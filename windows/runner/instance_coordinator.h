#ifndef RUNNER_INSTANCE_COORDINATOR_H_
#define RUNNER_INSTANCE_COORDINATOR_H_

#include <windows.h>

#include <string>

class InstanceCoordinator {
 public:
  explicit InstanceCoordinator(const std::wstring& application_identity);
  ~InstanceCoordinator();

  InstanceCoordinator(const InstanceCoordinator&) = delete;
  InstanceCoordinator& operator=(const InstanceCoordinator&) = delete;

  bool IsValid() const;
  bool TryAcquirePrimaryInstance();
  bool ActivateExistingInstance(DWORD timeout_milliseconds) const;

  bool RegisterWindow(HWND window);
  bool MarkWindowReady(HWND window);
  void UnregisterWindow(HWND window);

  UINT activation_message() const;

 private:
  std::wstring mutex_name_;
  std::wstring window_property_name_;
  UINT activation_message_ = 0;
  HANDLE mutex_ = nullptr;
  bool owns_mutex_ = false;
};

#endif  // RUNNER_INSTANCE_COORDINATOR_H_
