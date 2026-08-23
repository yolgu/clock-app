#include "windows_version.h"

#include <windows.h>

bool IsClockRhythmSupportedWindowsVersion() {
  OSVERSIONINFOEXW version{};
  version.dwOSVersionInfoSize = sizeof(version);
  version.dwMajorVersion = 10;
  version.dwBuildNumber = kClockRhythmMinimumWindowsBuild;

  DWORDLONG condition_mask = 0;
  condition_mask = ::VerSetConditionMask(
      condition_mask, VER_MAJORVERSION, VER_GREATER_EQUAL);
  condition_mask = ::VerSetConditionMask(
      condition_mask, VER_BUILDNUMBER, VER_GREATER_EQUAL);
  return ::VerifyVersionInfoW(&version, VER_MAJORVERSION | VER_BUILDNUMBER,
                              condition_mask) != FALSE;
}
