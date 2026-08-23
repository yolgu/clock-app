#include "window_placement.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>

namespace {

constexpr std::uint32_t kDefaultDpi = 96;
constexpr std::uint32_t kMinimumValidDpi = 48;
constexpr std::uint32_t kMaximumValidDpi = 768;

bool IsValidBounds(const PhysicalWindowBounds& bounds) {
  return bounds.width > 0 && bounds.height > 0;
}

bool IsValidDpi(std::uint32_t dpi) {
  return dpi >= kMinimumValidDpi && dpi <= kMaximumValidDpi;
}

std::int64_t Right(const PhysicalWindowBounds& bounds) {
  return static_cast<std::int64_t>(bounds.left) + bounds.width;
}

std::int64_t Bottom(const PhysicalWindowBounds& bounds) {
  return static_cast<std::int64_t>(bounds.top) + bounds.height;
}

std::int64_t OverlapArea(const PhysicalWindowBounds& left,
                         const PhysicalWindowBounds& right) {
  const std::int64_t overlap_width = std::max<std::int64_t>(
      0, std::min(Right(left), Right(right)) -
             std::max<std::int64_t>(left.left, right.left));
  const std::int64_t overlap_height = std::max<std::int64_t>(
      0, std::min(Bottom(left), Bottom(right)) -
             std::max<std::int64_t>(left.top, right.top));
  return overlap_width * overlap_height;
}

long double CenterDistanceSquared(const PhysicalWindowBounds& left,
                                  const PhysicalWindowBounds& right) {
  const long double left_center_x =
      static_cast<long double>(left.left) + left.width / 2.0L;
  const long double left_center_y =
      static_cast<long double>(left.top) + left.height / 2.0L;
  const long double right_center_x =
      static_cast<long double>(right.left) + right.width / 2.0L;
  const long double right_center_y =
      static_cast<long double>(right.top) + right.height / 2.0L;
  const long double horizontal = left_center_x - right_center_x;
  const long double vertical = left_center_y - right_center_y;
  return horizontal * horizontal + vertical * vertical;
}

std::optional<std::int32_t> ScaleDimension(std::int32_t value,
                                           std::uint32_t target_dpi,
                                           std::uint32_t source_dpi) {
  const std::int64_t scaled =
      (static_cast<std::int64_t>(value) * target_dpi + source_dpi / 2) /
      source_dpi;
  if (scaled <= 0 || scaled > std::numeric_limits<std::int32_t>::max()) {
    return std::nullopt;
  }
  return static_cast<std::int32_t>(scaled);
}

const PhysicalMonitorWorkArea* SelectMonitor(
    const PhysicalWindowBounds& stored,
    const std::vector<PhysicalMonitorWorkArea>& monitors) {
  const PhysicalMonitorWorkArea* selected = nullptr;
  std::int64_t greatest_overlap = -1;
  for (const PhysicalMonitorWorkArea& monitor : monitors) {
    if (!IsValidBounds(monitor.bounds) || !IsValidDpi(monitor.dpi)) {
      continue;
    }
    const std::int64_t overlap = OverlapArea(stored, monitor.bounds);
    if (selected == nullptr || overlap > greatest_overlap) {
      selected = &monitor;
      greatest_overlap = overlap;
    }
  }
  if (selected == nullptr || greatest_overlap > 0) {
    return selected;
  }

  long double shortest_distance = CenterDistanceSquared(stored, selected->bounds);
  for (const PhysicalMonitorWorkArea& monitor : monitors) {
    if (!IsValidBounds(monitor.bounds) || !IsValidDpi(monitor.dpi)) {
      continue;
    }
    const long double distance =
        CenterDistanceSquared(stored, monitor.bounds);
    if (distance < shortest_distance) {
      selected = &monitor;
      shortest_distance = distance;
    }
  }
  return selected;
}

}  // namespace

std::optional<PhysicalWindowPlacement> RestorePhysicalWindowPlacement(
    const PhysicalWindowPlacement& stored,
    const std::vector<PhysicalMonitorWorkArea>& monitors,
    std::int32_t minimum_logical_width,
    std::int32_t minimum_logical_height) {
  if (!IsValidBounds(stored.bounds) || !IsValidDpi(stored.dpi) ||
      minimum_logical_width <= 0 || minimum_logical_height <= 0) {
    return std::nullopt;
  }
  const PhysicalMonitorWorkArea* target =
      SelectMonitor(stored.bounds, monitors);
  if (target == nullptr) {
    return std::nullopt;
  }

  const std::optional<std::int32_t> scaled_width =
      ScaleDimension(stored.bounds.width, target->dpi, stored.dpi);
  const std::optional<std::int32_t> scaled_height =
      ScaleDimension(stored.bounds.height, target->dpi, stored.dpi);
  const std::optional<std::int32_t> minimum_width =
      ScaleDimension(minimum_logical_width, target->dpi, kDefaultDpi);
  const std::optional<std::int32_t> minimum_height =
      ScaleDimension(minimum_logical_height, target->dpi, kDefaultDpi);
  if (!scaled_width.has_value() || !scaled_height.has_value() ||
      !minimum_width.has_value() || !minimum_height.has_value()) {
    return std::nullopt;
  }

  const std::int32_t restored_width =
      target->bounds.width < minimum_width.value()
          ? target->bounds.width
          : std::clamp(scaled_width.value(), minimum_width.value(),
                       target->bounds.width);
  const std::int32_t restored_height =
      target->bounds.height < minimum_height.value()
          ? target->bounds.height
          : std::clamp(scaled_height.value(), minimum_height.value(),
                       target->bounds.height);
  const std::int64_t maximum_left =
      Right(target->bounds) - restored_width;
  const std::int64_t maximum_top =
      Bottom(target->bounds) - restored_height;
  const std::int32_t restored_left = static_cast<std::int32_t>(
      std::clamp<std::int64_t>(stored.bounds.left, target->bounds.left,
                               maximum_left));
  const std::int32_t restored_top = static_cast<std::int32_t>(
      std::clamp<std::int64_t>(stored.bounds.top, target->bounds.top,
                               maximum_top));
  return PhysicalWindowPlacement{
      PhysicalWindowBounds{restored_left, restored_top, restored_width,
                           restored_height},
      target->dpi};
}
