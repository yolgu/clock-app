#include <windows.h>

#include <iostream>
#include <filesystem>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "auto_start_bridge.h"
#include "local_state_file.h"
#include "window_placement.h"
#include "windows_version.h"

namespace {

constexpr const wchar_t kRunRegistryPath[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";

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

struct RegistryReadResult {
  LSTATUS status;
  std::optional<std::wstring> value;
};

RegistryReadResult ReadExactRegistration(const std::wstring& name) {
  RegistryKey key;
  const LSTATUS open_status = ::RegOpenKeyExW(
      HKEY_CURRENT_USER, kRunRegistryPath, 0, KEY_QUERY_VALUE, key.receive());
  if (open_status == ERROR_FILE_NOT_FOUND) {
    return RegistryReadResult{ERROR_SUCCESS, std::nullopt};
  }
  if (open_status != ERROR_SUCCESS) {
    return RegistryReadResult{open_status, std::nullopt};
  }

  DWORD type = 0;
  DWORD size_bytes = 0;
  LSTATUS query_status =
      ::RegQueryValueExW(key.get(), name.c_str(), nullptr, &type, nullptr,
                         &size_bytes);
  if (query_status == ERROR_FILE_NOT_FOUND) {
    return RegistryReadResult{ERROR_SUCCESS, std::nullopt};
  }
  if (query_status != ERROR_SUCCESS || type != REG_SZ ||
      size_bytes < sizeof(wchar_t) || size_bytes % sizeof(wchar_t) != 0) {
    return RegistryReadResult{query_status == ERROR_SUCCESS ? ERROR_INVALID_DATA
                                                            : query_status,
                              std::nullopt};
  }

  std::vector<wchar_t> value(size_bytes / sizeof(wchar_t), L'\0');
  query_status = ::RegQueryValueExW(
      key.get(), name.c_str(), nullptr, &type,
      reinterpret_cast<LPBYTE>(value.data()), &size_bytes);
  if (query_status != ERROR_SUCCESS) {
    return RegistryReadResult{query_status, std::nullopt};
  }
  value.back() = L'\0';
  return RegistryReadResult{ERROR_SUCCESS, std::wstring(value.data())};
}

bool WriteExactRegistration(const std::wstring& name,
                            const std::wstring& value) {
  RegistryKey key;
  const LSTATUS open_status = ::RegCreateKeyExW(
      HKEY_CURRENT_USER, kRunRegistryPath, 0, nullptr, 0,
      KEY_QUERY_VALUE | KEY_SET_VALUE, nullptr, key.receive(), nullptr);
  if (open_status != ERROR_SUCCESS) {
    return false;
  }
  const DWORD size_bytes =
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t));
  return ::RegSetValueExW(
             key.get(), name.c_str(), 0, REG_SZ,
             reinterpret_cast<const BYTE*>(value.c_str()), size_bytes) ==
         ERROR_SUCCESS;
}

void DeleteExactRegistration(const std::wstring& name) {
  RegistryKey key;
  if (::RegOpenKeyExW(HKEY_CURRENT_USER, kRunRegistryPath, 0, KEY_SET_VALUE,
                      key.receive()) == ERROR_SUCCESS) {
    ::RegDeleteValueW(key.get(), name.c_str());
  }
}

class OwnedRegistration {
 public:
  explicit OwnedRegistration(std::wstring name) : name_(std::move(name)) {}
  ~OwnedRegistration() { DeleteExactRegistration(name_); }

  OwnedRegistration(const OwnedRegistration&) = delete;
  OwnedRegistration& operator=(const OwnedRegistration&) = delete;

 private:
  std::wstring name_;
};

bool IsSynchronized(const AutoStartResult& result,
                    bool expected_actual_enabled) {
  return result.status == AutoStartStatus::kSynchronized &&
         result.actual_enabled.has_value() &&
         result.actual_enabled.value() == expected_actual_enabled &&
         result.error_code.empty();
}

int Fail(const wchar_t* message) {
  std::wcerr << message << std::endl;
  return 1;
}

bool SameBounds(const PhysicalWindowBounds& actual,
                const PhysicalWindowBounds& expected) {
  return actual.left == expected.left && actual.top == expected.top &&
         actual.width == expected.width && actual.height == expected.height;
}

bool VerifyMixedDpiPlacementContract() {
  const std::vector<PhysicalMonitorWorkArea> mixed_monitors{
      PhysicalMonitorWorkArea{PhysicalWindowBounds{0, 0, 1920, 1040}, 96},
      PhysicalMonitorWorkArea{PhysicalWindowBounds{1920, 0, 1920, 1040}, 144}};
  const PhysicalWindowPlacement stored_on_150_percent{
      PhysicalWindowBounds{2100, 20, 1380, 1020}, 144};
  const std::optional<PhysicalWindowPlacement> same_monitor =
      RestorePhysicalWindowPlacement(stored_on_150_percent, mixed_monitors,
                                     720, 560);
  if (!same_monitor.has_value() || same_monitor->dpi != 144 ||
      !SameBounds(same_monitor->bounds, stored_on_150_percent.bounds)) {
    return false;
  }

  const std::vector<PhysicalMonitorWorkArea> primary_only{
      PhysicalMonitorWorkArea{PhysicalWindowBounds{0, 0, 1920, 1040}, 96}};
  const std::optional<PhysicalWindowPlacement> moved_to_100_percent =
      RestorePhysicalWindowPlacement(stored_on_150_percent, primary_only, 720,
                                     560);
  if (!moved_to_100_percent.has_value() ||
      moved_to_100_percent->dpi != 96 ||
      !SameBounds(moved_to_100_percent->bounds,
                  PhysicalWindowBounds{1000, 20, 920, 680})) {
    return false;
  }

  const std::vector<PhysicalMonitorWorkArea> secondary_only{
      PhysicalMonitorWorkArea{PhysicalWindowBounds{1920, 0, 1920, 1040}, 144}};
  const PhysicalWindowPlacement stored_on_removed_100_percent{
      PhysicalWindowBounds{4000, 100, 920, 680}, 96};
  const std::optional<PhysicalWindowPlacement> moved_to_150_percent =
      RestorePhysicalWindowPlacement(stored_on_removed_100_percent,
                                     secondary_only, 720, 560);
  return moved_to_150_percent.has_value() &&
         moved_to_150_percent->dpi == 144 &&
         SameBounds(moved_to_150_percent->bounds,
                    PhysicalWindowBounds{2460, 20, 1380, 1020});
}

class OwnedLocalStateRoot {
 public:
  explicit OwnedLocalStateRoot(std::filesystem::path root)
      : root_(std::move(root)) {}
  ~OwnedLocalStateRoot() {
    std::error_code error;
    std::filesystem::remove_all(root_, error);
  }

  OwnedLocalStateRoot(const OwnedLocalStateRoot&) = delete;
  OwnedLocalStateRoot& operator=(const OwnedLocalStateRoot&) = delete;

 private:
  std::filesystem::path root_;
};

bool VerifyLocalStateContract() {
  const LocalStateFile production_file(L"dev.wndls.clockrhythm");
  const std::optional<LocalStatePaths> production_paths =
      production_file.ResolvePaths();
  if (!production_paths.has_value() || production_paths->root.empty() ||
      production_paths->directory.find(production_paths->root + L"\\") != 0 ||
      production_paths->file !=
          production_paths->directory + L"\\window-state.json") {
    return false;
  }

  std::vector<wchar_t> temporary_buffer(MAX_PATH, L'\0');
  const DWORD temporary_length = ::GetTempPathW(
      static_cast<DWORD>(temporary_buffer.size()), temporary_buffer.data());
  if (temporary_length == 0 || temporary_length >= temporary_buffer.size()) {
    return false;
  }
  const std::filesystem::path test_root =
      std::filesystem::path(temporary_buffer.data()) /
      (L"ClockRhythmLifecycleNativeTest-" +
       std::to_wstring(::GetCurrentProcessId()));
  const OwnedLocalStateRoot cleanup(test_root);
  const LocalStateFile test_file(L"dev.wndls.clockrhythm.lifecycle_test",
                                 test_root.wstring());
  const std::vector<std::uint8_t> first{'o', 'l', 'd'};
  const std::vector<std::uint8_t> second{'n', 'e', 'w'};
  if (!test_file.WriteAtomic(first) || !test_file.WriteAtomic(second)) {
    return false;
  }
  const LocalStateReadResult read = test_file.Read();
  const std::optional<LocalStatePaths> paths = test_file.ResolvePaths();
  if (read.status != LocalStateReadStatus::kSuccess || read.bytes != second ||
      !paths.has_value() ||
      std::filesystem::exists(paths->file + L".tmp")) {
    return false;
  }
  return test_file.Delete() &&
         test_file.Read().status == LocalStateReadStatus::kMissing;
}

}  // namespace

int wmain(int argument_count, wchar_t** arguments) {
  static_assert(kClockRhythmMinimumWindowsBuild == 17763);
  if (!IsClockRhythmSupportedWindowsVersion()) {
    return Fail(L"The native test host is below Windows 10 build 17763.");
  }
  if (!VerifyMixedDpiPlacementContract()) {
    return Fail(L"The 100/150 percent physical placement contract failed.");
  }
  if (!VerifyLocalStateContract()) {
    return Fail(L"The Local AppData atomic state contract failed.");
  }
  if (argument_count != 2 || arguments[1] == nullptr) {
    return Fail(L"Expected one harness-owned registry value name.");
  }
  const std::wstring registration_name(arguments[1]);
  if (registration_name.rfind(L"Clock Rhythm Lifecycle Test ", 0) != 0) {
    return Fail(L"Refusing a registration outside the lifecycle test prefix.");
  }

  const std::wstring sibling_registration_name = registration_name + L".Sibling";
  const RegistryReadResult initial = ReadExactRegistration(registration_name);
  const RegistryReadResult initial_sibling =
      ReadExactRegistration(sibling_registration_name);
  if (initial.status != ERROR_SUCCESS || initial.value.has_value() ||
      initial_sibling.status != ERROR_SUCCESS ||
      initial_sibling.value.has_value()) {
    return Fail(L"The harness registration already exists; nothing was changed.");
  }
  const OwnedRegistration cleanup(registration_name);
  const OwnedRegistration sibling_cleanup(sibling_registration_name);
  const std::wstring sibling_value = L"harness-owned sibling sentinel";
  if (!WriteExactRegistration(sibling_registration_name, sibling_value)) {
    return Fail(L"Could not create the harness-owned sibling value.");
  }
  const AutoStartBridge bridge(AutoStartConfiguration{
      registration_name, L"ClockRhythmLifecycleNativeTest", std::wstring()});
  const std::wstring expected_command = bridge.ExpectedUnpackagedCommand();
  if (expected_command.empty()) {
    return Fail(L"Could not derive the quoted test executable command.");
  }

  const AutoStartResult enabled = bridge.Reconcile(true);
  if (!IsSynchronized(enabled, true)) {
    return Fail(L"Unpackaged enable reconciliation failed.");
  }
  const RegistryReadResult enabled_value =
      ReadExactRegistration(registration_name);
  if (enabled_value.status != ERROR_SUCCESS ||
      enabled_value.value != expected_command) {
    return Fail(L"The HKCU Run command is not exact or correctly quoted.");
  }

  if (!WriteExactRegistration(registration_name, L"broken test command")) {
    return Fail(L"Could not inject the exact harness-owned stale value.");
  }
  const AutoStartResult repaired = bridge.Reconcile(true);
  const RegistryReadResult repaired_value =
      ReadExactRegistration(registration_name);
  if (!IsSynchronized(repaired, true) ||
      repaired_value.status != ERROR_SUCCESS ||
      repaired_value.value != expected_command) {
    return Fail(L"Unpackaged reconciliation did not repair its exact value.");
  }

  const AutoStartResult disabled = bridge.Reconcile(false);
  const RegistryReadResult final_value = ReadExactRegistration(registration_name);
  const RegistryReadResult final_sibling =
      ReadExactRegistration(sibling_registration_name);
  if (!IsSynchronized(disabled, false) ||
      final_value.status != ERROR_SUCCESS || final_value.value.has_value() ||
      final_sibling.status != ERROR_SUCCESS ||
      final_sibling.value != sibling_value) {
    return Fail(L"Unpackaged disable did not remove its exact value.");
  }

  std::wcout << L"Windows native autostart contract passed." << std::endl;
  return 0;
}
