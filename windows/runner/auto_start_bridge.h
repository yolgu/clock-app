#ifndef RUNNER_AUTO_START_BRIDGE_H_
#define RUNNER_AUTO_START_BRIDGE_H_

#include <optional>
#include <string>

enum class AutoStartStatus { kSynchronized, kNeedsUserAction, kError };

struct AutoStartResult {
  bool desired_enabled;
  std::optional<bool> actual_enabled;
  AutoStartStatus status;
  std::string error_code;
};

struct AutoStartConfiguration {
  std::wstring registration_name;
  std::wstring startup_task_id;
  std::wstring executable_path;
};

class AutoStartBridge {
 public:
  explicit AutoStartBridge(AutoStartConfiguration configuration);

  AutoStartResult Reconcile(bool desired_enabled) const;
  std::wstring ExpectedUnpackagedCommand() const;

 private:
  AutoStartResult ReconcileUnpackaged(bool desired_enabled) const;
  AutoStartResult ReconcilePackaged(bool desired_enabled) const;

  AutoStartConfiguration configuration_;
};

#endif  // RUNNER_AUTO_START_BRIDGE_H_
