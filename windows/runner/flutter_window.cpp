#include "flutter_window.h"

#include <cstdint>
#include <limits>
#include <optional>
#include <utility>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"
#include "window_placement.h"

namespace {

constexpr UINT kRequestApplicationExitMessage = WM_APP + 0x31;

flutter::EncodableValue AutoStartResultValue(const AutoStartResult& result) {
  std::string status;
  switch (result.status) {
    case AutoStartStatus::kSynchronized:
      status = "synchronized";
      break;
    case AutoStartStatus::kNeedsUserAction:
      status = "needsUserAction";
      break;
    case AutoStartStatus::kError:
      status = "error";
      break;
  }
  flutter::EncodableMap response;
  response[flutter::EncodableValue("desiredEnabled")] =
      flutter::EncodableValue(result.desired_enabled);
  response[flutter::EncodableValue("actualEnabled")] =
      result.actual_enabled.has_value()
          ? flutter::EncodableValue(result.actual_enabled.value())
          : flutter::EncodableValue();
  response[flutter::EncodableValue("status")] = flutter::EncodableValue(status);
  response[flutter::EncodableValue("errorCode")] =
      result.error_code.empty() ? flutter::EncodableValue()
                                : flutter::EncodableValue(result.error_code);
  return flutter::EncodableValue(response);
}

const flutter::EncodableMap* ArgumentsMap(
    const flutter::MethodCall<flutter::EncodableValue>& method_call) {
  const flutter::EncodableValue* arguments = method_call.arguments();
  return arguments == nullptr ? nullptr
                              : std::get_if<flutter::EncodableMap>(arguments);
}

const flutter::EncodableValue* MapValue(const flutter::EncodableMap& map,
                                        const char* key) {
  const auto found = map.find(flutter::EncodableValue(key));
  return found == map.end() ? nullptr : &found->second;
}

BOOL CALLBACK AddPhysicalMonitorWorkArea(HMONITOR monitor,
                                         HDC device_context,
                                         LPRECT monitor_bounds,
                                         LPARAM parameter) {
  auto* work_areas =
      reinterpret_cast<std::vector<PhysicalMonitorWorkArea>*>(parameter);
  MONITORINFO information{};
  information.cbSize = sizeof(information);
  if (::GetMonitorInfoW(monitor, &information)) {
    const RECT bounds = information.rcWork;
    work_areas->push_back(PhysicalMonitorWorkArea{
        PhysicalWindowBounds{bounds.left, bounds.top,
                             bounds.right - bounds.left,
                             bounds.bottom - bounds.top},
        FlutterDesktopGetDpiForMonitor(monitor)});
  }
  return TRUE;
}

std::optional<std::int32_t> EncodableInteger(
    const flutter::EncodableValue* value) {
  if (value == nullptr) {
    return std::nullopt;
  }
  if (const auto* int32_value = std::get_if<std::int32_t>(value)) {
    return *int32_value;
  }
  if (const auto* int64_value = std::get_if<std::int64_t>(value);
      int64_value != nullptr &&
      *int64_value >= std::numeric_limits<std::int32_t>::min() &&
      *int64_value <= std::numeric_limits<std::int32_t>::max()) {
    return static_cast<std::int32_t>(*int64_value);
  }
  return std::nullopt;
}

flutter::EncodableValue PlacementValue(
    const PhysicalWindowPlacement& placement) {
  flutter::EncodableMap response;
  response[flutter::EncodableValue("left")] =
      flutter::EncodableValue(placement.bounds.left);
  response[flutter::EncodableValue("top")] =
      flutter::EncodableValue(placement.bounds.top);
  response[flutter::EncodableValue("width")] =
      flutter::EncodableValue(placement.bounds.width);
  response[flutter::EncodableValue("height")] =
      flutter::EncodableValue(placement.bounds.height);
  response[flutter::EncodableValue("dpi")] =
      flutter::EncodableValue(static_cast<std::int32_t>(placement.dpi));
  return flutter::EncodableValue(response);
}

std::optional<PhysicalWindowPlacement> CapturePhysicalPlacement(HWND window) {
  RECT bounds{};
  if (window == nullptr || !::GetWindowRect(window, &bounds)) {
    return std::nullopt;
  }
  const HMONITOR monitor =
      ::MonitorFromRect(&bounds, MONITOR_DEFAULTTONEAREST);
  const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  if (dpi == 0) {
    return std::nullopt;
  }
  return PhysicalWindowPlacement{
      PhysicalWindowBounds{bounds.left, bounds.top, bounds.right - bounds.left,
                           bounds.bottom - bounds.top},
      dpi};
}

}  // namespace

FlutterWindow::FlutterWindow(
    const flutter::DartProject& project,
    InstanceCoordinator* instance_coordinator,
    std::string application_identity,
    std::wstring application_identity_wide,
    AutoStartConfiguration auto_start_configuration,
    bool starts_hidden)
    : project_(project),
      instance_coordinator_(instance_coordinator),
      application_identity_(std::move(application_identity)),
      local_state_file_(std::move(application_identity_wide)),
      auto_start_bridge_(std::move(auto_start_configuration)),
      starts_hidden_(starts_hidden) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }
  if (instance_coordinator_ == nullptr ||
      !instance_coordinator_->RegisterWindow(GetHandle())) {
    return false;
  }
  window_registered_ = true;

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "clock_rhythm/windows_window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleWindowMethodCall(call, std::move(result));
      });
  auto_start_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "clock_rhythm/windows_auto_start",
          &flutter::StandardMethodCodec::GetInstance());
  auto_start_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleAutoStartMethodCall(call, std::move(result));
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([this]() {
    if (instance_coordinator_ != nullptr) {
      instance_coordinator_->MarkWindowReady(GetHandle());
    }
#if defined(CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START)
    if (starts_hidden_) {
      Activate(restore_maximized_);
    }
#endif
    if (!starts_hidden_) {
      Activate(restore_maximized_);
    }
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (window_registered_ && instance_coordinator_ != nullptr) {
    instance_coordinator_->UnregisterWindow(GetHandle());
    window_registered_ = false;
  }
  window_channel_.reset();
  auto_start_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (instance_coordinator_ != nullptr &&
      message == instance_coordinator_->activation_message()) {
    starts_hidden_ = false;
    Activate(restore_maximized_);
    return 0;
  }
  if (message == WM_CLOSE) {
    Hide();
    return 0;
  }
  if (message == kRequestApplicationExitMessage) {
    SetQuitOnClose(true);
    Destroy();
    ::PostQuitMessage(0);
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::HandleWindowMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();
  if (method == "getConfiguration") {
    flutter::EncodableMap response;
    response[flutter::EncodableValue("applicationIdentity")] =
        flutter::EncodableValue(application_identity_);
    response[flutter::EncodableValue("startsHidden")] =
        flutter::EncodableValue(starts_hidden_);
    result->Success(flutter::EncodableValue(response));
    return;
  }
  if (method == "captureNormalWindowPlacement") {
    const std::optional<PhysicalWindowPlacement> placement =
        CapturePhysicalPlacement(GetHandle());
    if (!placement.has_value()) {
      result->Error("window-placement-unavailable",
                    "Could not capture the physical window placement.");
      return;
    }
    result->Success(PlacementValue(placement.value()));
    return;
  }
  if (method == "restoreNormalWindowPlacement") {
    const flutter::EncodableMap* arguments = ArgumentsMap(method_call);
    const std::optional<std::int32_t> left = arguments == nullptr
                                                 ? std::nullopt
                                                 : EncodableInteger(
                                                       MapValue(*arguments, "left"));
    const std::optional<std::int32_t> top = arguments == nullptr
                                                ? std::nullopt
                                                : EncodableInteger(
                                                      MapValue(*arguments, "top"));
    const std::optional<std::int32_t> width = arguments == nullptr
                                                  ? std::nullopt
                                                  : EncodableInteger(
                                                        MapValue(*arguments, "width"));
    const std::optional<std::int32_t> height = arguments == nullptr
                                                   ? std::nullopt
                                                   : EncodableInteger(
                                                         MapValue(*arguments, "height"));
    const std::optional<std::int32_t> source_dpi =
        arguments == nullptr
            ? std::nullopt
            : EncodableInteger(MapValue(*arguments, "sourceDpi"));
    if (!left.has_value() || !top.has_value() || !width.has_value() ||
        !height.has_value() || !source_dpi.has_value() ||
        source_dpi.value() <= 0) {
      result->Error("invalid-arguments", "Invalid physical window placement.");
      return;
    }

    std::vector<PhysicalMonitorWorkArea> work_areas;
    ::EnumDisplayMonitors(nullptr, nullptr, AddPhysicalMonitorWorkArea,
                          reinterpret_cast<LPARAM>(&work_areas));
    const std::optional<PhysicalWindowPlacement> restored =
        RestorePhysicalWindowPlacement(
            PhysicalWindowPlacement{
                PhysicalWindowBounds{left.value(), top.value(), width.value(),
                                     height.value()},
                static_cast<std::uint32_t>(source_dpi.value())},
            work_areas, 720, 560);
    if (!restored.has_value()) {
      result->Error("monitor-unavailable",
                    "No valid physical monitor work area is available.");
      return;
    }
    const PhysicalWindowBounds restored_bounds = restored->bounds;
    if (!::SetWindowPos(GetHandle(), nullptr, restored_bounds.left,
                        restored_bounds.top, restored_bounds.width,
                        restored_bounds.height,
                        SWP_NOACTIVATE | SWP_NOZORDER)) {
      result->Error("window-placement-failed",
                    "Could not restore the physical window placement.");
      return;
    }
    result->Success(PlacementValue(restored.value()));
    return;
  }
  const flutter::EncodableMap* local_state_arguments =
      ArgumentsMap(method_call);
  const flutter::EncodableValue* identity_value =
      local_state_arguments == nullptr
          ? nullptr
          : MapValue(*local_state_arguments, "applicationIdentity");
  const std::string* requested_identity =
      identity_value == nullptr ? nullptr
                                : std::get_if<std::string>(identity_value);
  const bool identity_matches = requested_identity != nullptr &&
                                *requested_identity == application_identity_;
  if (method == "getLocalStateLocation") {
    if (!identity_matches) {
      result->Error("invalid-identity", "Invalid local-state identity.");
      return;
    }
    const std::optional<LocalStatePaths> paths =
        local_state_file_.ResolvePaths();
    if (!paths.has_value()) {
      result->Error("local-state-unavailable",
                    "Could not resolve Local AppData.");
      return;
    }
    flutter::EncodableMap response;
    response[flutter::EncodableValue("root")] =
        flutter::EncodableValue(Utf8FromUtf16(paths->root.c_str()));
    response[flutter::EncodableValue("directory")] =
        flutter::EncodableValue(Utf8FromUtf16(paths->directory.c_str()));
    response[flutter::EncodableValue("file")] =
        flutter::EncodableValue(Utf8FromUtf16(paths->file.c_str()));
    result->Success(flutter::EncodableValue(response));
    return;
  }
  if (method == "readLocalWindowState") {
    if (!identity_matches) {
      result->Error("invalid-identity", "Invalid local-state identity.");
      return;
    }
    LocalStateReadResult read = local_state_file_.Read();
    if (read.status == LocalStateReadStatus::kMissing) {
      result->Success();
    } else if (read.status == LocalStateReadStatus::kSuccess) {
      result->Success(flutter::EncodableValue(std::move(read.bytes)));
    } else {
      result->Error("local-state-read-failed",
                    "Could not read Local AppData window state.");
    }
    return;
  }
  if (method == "writeLocalWindowStateAtomic") {
    const flutter::EncodableValue* document_value =
        local_state_arguments == nullptr
            ? nullptr
            : MapValue(*local_state_arguments, "document");
    const std::string* document =
        document_value == nullptr ? nullptr
                                  : std::get_if<std::string>(document_value);
    if (!identity_matches || document == nullptr) {
      result->Error("invalid-arguments", "Invalid local-state document.");
      return;
    }
    const std::vector<std::uint8_t> bytes(document->begin(), document->end());
    if (!local_state_file_.WriteAtomic(bytes)) {
      result->Error("local-state-write-failed",
                    "Could not atomically write Local AppData window state.");
      return;
    }
    result->Success();
    return;
  }
  if (method == "deleteLocalWindowState") {
    if (!identity_matches || !local_state_file_.Delete()) {
      result->Error("local-state-delete-failed",
                    "Could not delete Local AppData window state.");
      return;
    }
    result->Success();
    return;
  }
  if (method == "setRestoreMaximized") {
    const flutter::EncodableMap* arguments = ArgumentsMap(method_call);
    const flutter::EncodableValue* maximized_value =
        arguments == nullptr ? nullptr : MapValue(*arguments, "maximized");
    const bool* maximized =
        maximized_value == nullptr ? nullptr : std::get_if<bool>(maximized_value);
    if (maximized == nullptr) {
      result->Error("invalid-arguments", "Invalid maximized state.");
      return;
    }
    restore_maximized_ = *maximized;
    result->Success();
    return;
  }
  if (method == "activateWindow") {
    starts_hidden_ = false;
    Activate(restore_maximized_);
    result->Success();
    return;
  }
  if (method == "requestApplicationExit") {
    result->Success();
    ::PostMessageW(GetHandle(), kRequestApplicationExitMessage, 0, 0);
    return;
  }
  result->NotImplemented();
}

void FlutterWindow::HandleAutoStartMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() != "reconcile") {
    result->NotImplemented();
    return;
  }
  const flutter::EncodableMap* arguments = ArgumentsMap(method_call);
  const flutter::EncodableValue* desired_value =
      arguments == nullptr ? nullptr : MapValue(*arguments, "desiredEnabled");
  const bool* desired_enabled =
      desired_value == nullptr ? nullptr : std::get_if<bool>(desired_value);
  if (desired_enabled == nullptr) {
    result->Error("invalid-arguments", "Invalid desired autostart state.");
    return;
  }
  result->Success(
      AutoStartResultValue(auto_start_bridge_.Reconcile(*desired_enabled)));
}
