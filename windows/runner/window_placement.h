#ifndef RUNNER_WINDOW_PLACEMENT_H_
#define RUNNER_WINDOW_PLACEMENT_H_

#include <cstdint>
#include <optional>
#include <vector>

struct PhysicalWindowBounds {
  std::int32_t left;
  std::int32_t top;
  std::int32_t width;
  std::int32_t height;
};

struct PhysicalMonitorWorkArea {
  PhysicalWindowBounds bounds;
  std::uint32_t dpi;
};

struct PhysicalWindowPlacement {
  PhysicalWindowBounds bounds;
  std::uint32_t dpi;
};

std::optional<PhysicalWindowPlacement> RestorePhysicalWindowPlacement(
    const PhysicalWindowPlacement& stored,
    const std::vector<PhysicalMonitorWorkArea>& monitors,
    std::int32_t minimum_logical_width,
    std::int32_t minimum_logical_height);

#endif  // RUNNER_WINDOW_PLACEMENT_H_
