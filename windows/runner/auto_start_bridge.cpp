#include "auto_start_bridge.h"

#include <windows.h>
#include <appmodel.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/base.h>

#include <future>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace {

constexpr const wchar_t kRunRegistryPath[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr size_t kMaximumRunCommandLength = 260;

enum class PackageIdentityState { kUnpackaged, kPackaged, kError };

struct RegistryValueState {
  LSTATUS error = ERROR_SUCCESS;
  bool exists = false;
  bool matches = false;
};

class RegistryKey {
 public:
  RegistryKey() = default;
  ~RegistryKey() {
    if (value_ != nullptr) {
      ::RegCloseKey(value_);
    }
  }

  RegistryKey(const RegistryKey&) = delete;
  RegistryKey& operator=(const RegistryKey&) = delete;

  HKEY* receive() { return &value_; }
  HKEY get() const { return value_; }

 private:
  HKEY value_ = nullptr;
};

class ScopedWinrtApartment {
 public:
  ScopedWinrtApartment() {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
  }
  ~ScopedWinrtApartment() { winrt::uninit_apartment(); }

  ScopedWinrtApartment(const ScopedWinrtApartment&) = delete;
  ScopedWinrtApartment& operator=(const ScopedWinrtApartment&) = delete;
};

AutoStartResult Synchronized(bool desired_enabled, bool actual_enabled) {
  return AutoStartResult{desired_enabled, actual_enabled,
                         AutoStartStatus::kSynchronized, std::string()};
}

AutoStartResult NeedsUserAction(bool desired_enabled, bool actual_enabled) {
  return AutoStartResult{desired_enabled, actual_enabled,
                         AutoStartStatus::kNeedsUserAction, std::string()};
}

AutoStartResult Error(bool desired_enabled, const char* error_code) {
  return AutoStartResult{desired_enabled, std::nullopt, AutoStartStatus::kError,
                         std::string(error_code)};
}

PackageIdentityState DetectPackageIdentity() {
  UINT32 package_name_length = 0;
  const LONG result =
      ::GetCurrentPackageFullName(&package_name_length, nullptr);
  if (result == APPMODEL_ERROR_NO_PACKAGE) {
    return PackageIdentityState::kUnpackaged;
  }
  if (result == ERROR_INSUFFICIENT_BUFFER || result == ERROR_SUCCESS) {
    return PackageIdentityState::kPackaged;
  }
  return PackageIdentityState::kError;
}

std::wstring CurrentExecutablePath() {
  DWORD capacity = MAX_PATH;
  while (capacity <= 32768) {
    std::wstring buffer(capacity, L'\0');
    const DWORD length =
        ::GetModuleFileNameW(nullptr, buffer.data(), capacity);
    if (length == 0) {
      return std::wstring();
    }
    if (length < capacity) {
      buffer.resize(length);
      return buffer;
    }
    capacity *= 2;
  }
  return std::wstring();
}

RegistryValueState QueryRegistryValue(HKEY key,
                                      const std::wstring& registration_name,
                                      const std::wstring& expected_command) {
  DWORD type = 0;
  DWORD size_bytes = 0;
  LSTATUS result = ::RegQueryValueExW(key, registration_name.c_str(), nullptr,
                                     &type, nullptr, &size_bytes);
  if (result == ERROR_FILE_NOT_FOUND) {
    return RegistryValueState{};
  }
  if (result != ERROR_SUCCESS) {
    return RegistryValueState{result, false, false};
  }
  if (type != REG_SZ || size_bytes < sizeof(wchar_t) ||
      size_bytes % sizeof(wchar_t) != 0) {
    return RegistryValueState{ERROR_SUCCESS, true, false};
  }

  std::vector<wchar_t> value(size_bytes / sizeof(wchar_t), L'\0');
  result = ::RegQueryValueExW(
      key, registration_name.c_str(), nullptr, &type,
      reinterpret_cast<LPBYTE>(value.data()), &size_bytes);
  if (result != ERROR_SUCCESS) {
    return RegistryValueState{result, false, false};
  }
  value.back() = L'\0';
  return RegistryValueState{ERROR_SUCCESS, true,
                            expected_command == value.data()};
}

AutoStartResult ResultForPackagedState(
    bool desired_enabled,
    winrt::Windows::ApplicationModel::StartupTaskState state) {
  using winrt::Windows::ApplicationModel::StartupTaskState;
  switch (state) {
    case StartupTaskState::Enabled:
    case StartupTaskState::EnabledByPolicy:
      return desired_enabled ? Synchronized(true, true)
                             : NeedsUserAction(false, true);
    case StartupTaskState::Disabled:
    case StartupTaskState::DisabledByUser:
    case StartupTaskState::DisabledByPolicy:
      return desired_enabled ? NeedsUserAction(true, false)
                             : Synchronized(false, false);
  }
  return Error(desired_enabled, "startupTaskStateUnknown");
}

}  // namespace

AutoStartBridge::AutoStartBridge(AutoStartConfiguration configuration)
    : configuration_(std::move(configuration)) {}

AutoStartResult AutoStartBridge::Reconcile(bool desired_enabled) const {
  if (configuration_.registration_name.empty() ||
      configuration_.startup_task_id.empty()) {
    return Error(desired_enabled, "autostartConfigurationInvalid");
  }

  switch (DetectPackageIdentity()) {
    case PackageIdentityState::kUnpackaged:
      return ReconcileUnpackaged(desired_enabled);
    case PackageIdentityState::kPackaged:
      return ReconcilePackaged(desired_enabled);
    case PackageIdentityState::kError:
      return Error(desired_enabled, "packageIdentityUnavailable");
  }
  return Error(desired_enabled, "packageIdentityUnavailable");
}

std::wstring AutoStartBridge::ExpectedUnpackagedCommand() const {
  const std::wstring executable_path = configuration_.executable_path.empty()
                                           ? CurrentExecutablePath()
                                           : configuration_.executable_path;
  if (executable_path.empty() || executable_path.find(L'"') != std::wstring::npos) {
    return std::wstring();
  }
  return L"\"" + executable_path + L"\" --hidden";
}

AutoStartResult AutoStartBridge::ReconcileUnpackaged(
    bool desired_enabled) const {
  const std::wstring expected_command = ExpectedUnpackagedCommand();
  if (expected_command.empty()) {
    return Error(desired_enabled, "executablePathUnavailable");
  }
  if (expected_command.size() > kMaximumRunCommandLength) {
    return Error(desired_enabled, "autostartCommandTooLong");
  }

  RegistryKey run_key;
  LSTATUS open_result = ERROR_SUCCESS;
  if (desired_enabled) {
    open_result = ::RegCreateKeyExW(
        HKEY_CURRENT_USER, kRunRegistryPath, 0, nullptr, 0,
        KEY_QUERY_VALUE | KEY_SET_VALUE, nullptr, run_key.receive(), nullptr);
  } else {
    open_result = ::RegOpenKeyExW(HKEY_CURRENT_USER, kRunRegistryPath, 0,
                                 KEY_QUERY_VALUE | KEY_SET_VALUE,
                                 run_key.receive());
    if (open_result == ERROR_FILE_NOT_FOUND) {
      return Synchronized(false, false);
    }
  }
  if (open_result != ERROR_SUCCESS) {
    return Error(desired_enabled, "registryAccessDenied");
  }

  const RegistryValueState before = QueryRegistryValue(
      run_key.get(), configuration_.registration_name, expected_command);
  if (before.error != ERROR_SUCCESS) {
    return Error(desired_enabled, "registryReadFailed");
  }

  if (desired_enabled && !before.matches) {
    const DWORD command_size = static_cast<DWORD>(
        (expected_command.size() + 1) * sizeof(wchar_t));
    const LSTATUS write_result = ::RegSetValueExW(
        run_key.get(), configuration_.registration_name.c_str(), 0, REG_SZ,
        reinterpret_cast<const BYTE*>(expected_command.c_str()), command_size);
    if (write_result != ERROR_SUCCESS) {
      return Error(true, "registryWriteFailed");
    }
  } else if (!desired_enabled && before.exists) {
    const LSTATUS delete_result = ::RegDeleteValueW(
        run_key.get(), configuration_.registration_name.c_str());
    if (delete_result != ERROR_SUCCESS && delete_result != ERROR_FILE_NOT_FOUND) {
      return Error(false, "registryDeleteFailed");
    }
  }

  const RegistryValueState after = QueryRegistryValue(
      run_key.get(), configuration_.registration_name, expected_command);
  if (after.error != ERROR_SUCCESS) {
    return Error(desired_enabled, "registryReadFailed");
  }
  const bool actual_enabled = after.exists && after.matches;
  if (actual_enabled != desired_enabled) {
    return Error(desired_enabled, "registryReconciliationFailed");
  }
  return Synchronized(desired_enabled, actual_enabled);
}

AutoStartResult AutoStartBridge::ReconcilePackaged(
    bool desired_enabled) const {
  const std::wstring task_id = configuration_.startup_task_id;
  return std::async(std::launch::async, [desired_enabled, task_id]() {
           try {
             const ScopedWinrtApartment apartment;
             using winrt::Windows::ApplicationModel::StartupTask;
             using winrt::Windows::ApplicationModel::StartupTaskState;

             const StartupTask task =
                 StartupTask::GetAsync(winrt::hstring(task_id)).get();
             if (!task) {
               return Error(desired_enabled, "startupTaskUnavailable");
             }

             StartupTaskState state = task.State();
             if (desired_enabled) {
               if (state == StartupTaskState::Enabled ||
                   state == StartupTaskState::EnabledByPolicy) {
                 return Synchronized(true, true);
               }
               if (state == StartupTaskState::Disabled) {
                 state = task.RequestEnableAsync().get();
               }
               return ResultForPackagedState(true, state);
             }

             if (state == StartupTaskState::Enabled) {
               task.Disable();
               state = task.State();
             }
             return ResultForPackagedState(false, state);
           } catch (const winrt::hresult_error&) {
             return Error(desired_enabled, "startupTaskUnavailable");
           } catch (...) {
             return Error(desired_enabled, "startupTaskUnavailable");
           }
         }).get();
}
