enum RouteErrorKind { malformedCalendarDate, unknownLocation }

final class RouteError {
  const RouteError({required this.kind, required this.location});

  final RouteErrorKind kind;
  final String location;

  factory RouteError.malformedCalendarDate(String location) {
    return RouteError(
      kind: RouteErrorKind.malformedCalendarDate,
      location: location,
    );
  }

  factory RouteError.unknownLocation(String location) {
    return RouteError(kind: RouteErrorKind.unknownLocation, location: location);
  }
}
