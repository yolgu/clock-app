#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <appmodel.h>
#include <winrt/Windows.ApplicationModel.Activation.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/base.h>

#include <algorithm>
#include <optional>
#include <string>

#include "auto_start_bridge.h"
#include "flutter_window.h"
#include "instance_coordinator.h"
#include "utils.h"
#include "windows_version.h"

#ifndef CLOCK_RHYTHM_WINDOWS_IDENTITY
#define CLOCK_RHYTHM_WINDOWS_IDENTITY "dev.wndls.clockrhythm"
#endif

#ifndef CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME
#define CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME "Clock Rhythm"
#endif

#ifndef CLOCK_RHYTHM_STARTUP_TASK_ID
#define CLOCK_RHYTHM_STARTUP_TASK_ID "ClockRhythmStartup"
#endif

namespace {

class ScopedComInitializer {
 public:
  ScopedComInitializer()
      : result_(::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)) {}
  ~ScopedComInitializer() {
    if (SUCCEEDED(result_)) {
      ::CoUninitialize();
    }
  }

  ScopedComInitializer(const ScopedComInitializer&) = delete;
  ScopedComInitializer& operator=(const ScopedComInitializer&) = delete;

  bool succeeded() const { return SUCCEEDED(result_); }

 private:
  HRESULT result_;
};

std::optional<bool> IsPackagedStartupTaskActivation() {
  UINT32 package_name_length = 0;
  const LONG package_result =
      ::GetCurrentPackageFullName(&package_name_length, nullptr);
  if (package_result == APPMODEL_ERROR_NO_PACKAGE) {
    return false;
  }
  if (package_result != ERROR_INSUFFICIENT_BUFFER &&
      package_result != ERROR_SUCCESS) {
    return std::nullopt;
  }

  try {
    const auto activation_arguments =
        winrt::Windows::ApplicationModel::AppInstance::GetActivatedEventArgs();
    if (!activation_arguments) {
      return std::nullopt;
    }
    return activation_arguments.Kind() ==
           winrt::Windows::ApplicationModel::Activation::ActivationKind::
               StartupTask;
  } catch (const winrt::hresult_error&) {
    return std::nullopt;
  } catch (...) {
    return std::nullopt;
  }
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!IsClockRhythmSupportedWindowsVersion()) {
    return EXIT_FAILURE;
  }
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  const bool has_hidden_argument =
      std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--hidden") != command_line_arguments.end();
  const ScopedComInitializer com_initializer;
  if (!com_initializer.succeeded()) {
    return EXIT_FAILURE;
  }
  const std::optional<bool> packaged_startup_activation =
      IsPackagedStartupTaskActivation();
  if (!packaged_startup_activation.has_value()) {
    return EXIT_FAILURE;
  }
  const bool starts_hidden =
      has_hidden_argument || packaged_startup_activation.value();
  const std::string application_identity = CLOCK_RHYTHM_WINDOWS_IDENTITY;
  const std::wstring application_identity_wide =
      Utf16FromUtf8(application_identity.c_str());
  InstanceCoordinator instance_coordinator(application_identity_wide);
  if (!instance_coordinator.IsValid()) {
    return EXIT_FAILURE;
  }
  if (!instance_coordinator.TryAcquirePrimaryInstance()) {
    if (starts_hidden) {
      return EXIT_SUCCESS;
    }
    return instance_coordinator.ActivateExistingInstance(5000) ? EXIT_SUCCESS
                                                                : EXIT_FAILURE;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  flutter::DartProject project(L"data");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  AutoStartConfiguration auto_start_configuration{
      Utf16FromUtf8(CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME),
      Utf16FromUtf8(CLOCK_RHYTHM_STARTUP_TASK_ID), std::wstring()};
  FlutterWindow window(project, &instance_coordinator, application_identity,
                       application_identity_wide,
                       std::move(auto_start_configuration), starts_hidden);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(920, 680);
  if (!window.Create(L"Clock Rhythm", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(false);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  return EXIT_SUCCESS;
}
