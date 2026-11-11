import '../../shared/ui/public.dart' show LineGlyph;
import '../navigation/app_routes.dart';

/// The line glyph that stands for each destination wherever it is listed.
abstract final class DestinationIcons {
  static LineGlyph of(MainDestination destination) {
    return switch (destination) {
      MainDestination.clock => LineGlyph.clock,
      MainDestination.calendar => LineGlyph.calendar,
      MainDestination.data => LineGlyph.folder,
      MainDestination.theme => LineGlyph.palette,
      MainDestination.settings => LineGlyph.sliders,
    };
  }
}
