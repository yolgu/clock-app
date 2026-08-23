#include "instance_coordinator.h"

#include <sddl.h>

#include <algorithm>
#include <string>
#include <vector>

namespace {

const HANDLE kWindowPropertyMarker =
    reinterpret_cast<HANDLE>(static_cast<INT_PTR>(1));
constexpr DWORD kActivationPollIntervalMilliseconds = 50;
constexpr const wchar_t kReadyWindowPropertyName[] =
    L"ClockRhythm.Lifecycle.Ready";

std::wstring CurrentUserSid() {
  HANDLE token = nullptr;
  if (!::OpenProcessToken(::GetCurrentProcess(), TOKEN_QUERY, &token)) {
    return std::wstring();
  }

  DWORD required_size = 0;
  ::GetTokenInformation(token, TokenUser, nullptr, 0, &required_size);
  if (required_size == 0 || ::GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
    ::CloseHandle(token);
    return std::wstring();
  }

  std::vector<unsigned char> token_buffer(required_size);
  if (!::GetTokenInformation(token, TokenUser, token_buffer.data(),
                             required_size, &required_size)) {
    ::CloseHandle(token);
    return std::wstring();
  }
  ::CloseHandle(token);

  const auto* token_user =
      reinterpret_cast<const TOKEN_USER*>(token_buffer.data());
  LPWSTR sid_value = nullptr;
  if (!::ConvertSidToStringSidW(token_user->User.Sid, &sid_value)) {
    return std::wstring();
  }
  const std::wstring sid(sid_value);
  ::LocalFree(sid_value);
  return sid;
}

bool IsValidIdentity(const std::wstring& identity) {
  if (identity.empty() || identity.size() > 128) {
    return false;
  }
  return std::all_of(identity.begin(), identity.end(), [](wchar_t value) {
    return (value >= L'a' && value <= L'z') ||
           (value >= L'A' && value <= L'Z') ||
           (value >= L'0' && value <= L'9') || value == L'.' ||
           value == L'_' || value == L'-';
  });
}

struct WindowSearchContext {
  const std::wstring* property_name;
  HWND window = nullptr;
};

BOOL CALLBACK FindOwnedWindow(HWND window, LPARAM parameter) {
  auto* context = reinterpret_cast<WindowSearchContext*>(parameter);
  if (::GetPropW(window, context->property_name->c_str()) ==
      kWindowPropertyMarker) {
    context->window = window;
    return FALSE;
  }
  return TRUE;
}

}  // namespace

InstanceCoordinator::InstanceCoordinator(
    const std::wstring& application_identity) {
  const std::wstring user_sid = CurrentUserSid();
  if (!IsValidIdentity(application_identity) || user_sid.empty()) {
    return;
  }

  const std::wstring instance_key = application_identity + L"." + user_sid;
  mutex_name_ = L"Local\\ClockRhythm." + instance_key + L".Mutex";
  window_property_name_ = L"ClockRhythm." + instance_key + L".Window";
  const std::wstring activation_message_name =
      L"ClockRhythm." + instance_key + L".Activate";
  activation_message_ =
      ::RegisterWindowMessageW(activation_message_name.c_str());
}

InstanceCoordinator::~InstanceCoordinator() {
  if (owns_mutex_ && mutex_ != nullptr) {
    ::ReleaseMutex(mutex_);
  }
  if (mutex_ != nullptr) {
    ::CloseHandle(mutex_);
  }
}

bool InstanceCoordinator::IsValid() const {
  return !mutex_name_.empty() && !window_property_name_.empty() &&
         activation_message_ != 0;
}

bool InstanceCoordinator::TryAcquirePrimaryInstance() {
  if (!IsValid() || mutex_ != nullptr) {
    return false;
  }

  mutex_ = ::CreateMutexW(nullptr, FALSE, mutex_name_.c_str());
  if (mutex_ == nullptr) {
    return false;
  }
  const DWORD wait_result = ::WaitForSingleObject(mutex_, 0);
  if (wait_result == WAIT_OBJECT_0 || wait_result == WAIT_ABANDONED) {
    owns_mutex_ = true;
    return true;
  }
  return false;
}

bool InstanceCoordinator::ActivateExistingInstance(
    DWORD timeout_milliseconds) const {
  if (!IsValid()) {
    return false;
  }

  const ULONGLONG deadline = ::GetTickCount64() + timeout_milliseconds;
  do {
    WindowSearchContext context{&window_property_name_};
    ::EnumWindows(FindOwnedWindow, reinterpret_cast<LPARAM>(&context));
    if (context.window != nullptr) {
      DWORD process_id = 0;
      ::GetWindowThreadProcessId(context.window, &process_id);
      if (process_id != 0) {
        ::AllowSetForegroundWindow(process_id);
      }

      DWORD_PTR message_result = 0;
      const LRESULT sent = ::SendMessageTimeoutW(
          context.window, activation_message_, 0, 0,
          SMTO_ABORTIFHUNG | SMTO_BLOCK, 1000, &message_result);
      if (sent != 0) {
        return true;
      }
    }
    if (::GetTickCount64() >= deadline) {
      break;
    }
    ::Sleep(kActivationPollIntervalMilliseconds);
  } while (true);

  return false;
}

bool InstanceCoordinator::RegisterWindow(HWND window) {
  return window != nullptr && IsValid() &&
         ::SetPropW(window, window_property_name_.c_str(),
                    kWindowPropertyMarker) != FALSE;
}

bool InstanceCoordinator::MarkWindowReady(HWND window) {
  return window != nullptr &&
         ::SetPropW(window, kReadyWindowPropertyName, kWindowPropertyMarker) !=
             FALSE;
}

void InstanceCoordinator::UnregisterWindow(HWND window) {
  if (window != nullptr && !window_property_name_.empty()) {
    ::RemovePropW(window, kReadyWindowPropertyName);
    ::RemovePropW(window, window_property_name_.c_str());
  }
}

UINT InstanceCoordinator::activation_message() const {
  return activation_message_;
}
