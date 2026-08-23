#ifndef RUNNER_WINDOWS_VERSION_H_
#define RUNNER_WINDOWS_VERSION_H_

#include <cstdint>

constexpr std::uint32_t kClockRhythmMinimumWindowsBuild = 17763;

bool IsClockRhythmSupportedWindowsVersion();

#endif  // RUNNER_WINDOWS_VERSION_H_
