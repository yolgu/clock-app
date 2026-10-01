import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

/// Rounded glyphs that sit closest to SF Symbols in the Material set.
abstract final class DestinationIcons {
  static IconData of(MainDestination destination, {required bool selected}) {
    return switch (destination) {
      MainDestination.clock =>
        selected ? Icons.watch_later_rounded : Icons.watch_later_outlined,
      MainDestination.calendar =>
        selected ? Icons.calendar_month_rounded : Icons.calendar_month_outlined,
      MainDestination.data =>
        selected ? Icons.folder_rounded : Icons.folder_outlined,
      MainDestination.theme =>
        selected ? Icons.palette_rounded : Icons.palette_outlined,
      MainDestination.settings =>
        selected ? Icons.settings_rounded : Icons.settings_outlined,
    };
  }
}
