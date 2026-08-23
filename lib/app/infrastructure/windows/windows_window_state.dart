final class WindowsWindowBounds {
  const WindowsWindowBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int left;
  final int top;
  final int width;
  final int height;

  bool get isValid => width > 0 && height > 0;

  @override
  bool operator ==(Object other) {
    return other is WindowsWindowBounds &&
        left == other.left &&
        top == other.top &&
        width == other.width &&
        height == other.height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

final class WindowsWindowPlacement {
  const WindowsWindowPlacement({required this.bounds, required this.dpi});

  final WindowsWindowBounds bounds;
  final int dpi;

  bool get isValid => bounds.isValid && dpi >= 48 && dpi <= 768;

  @override
  bool operator ==(Object other) {
    return other is WindowsWindowPlacement &&
        bounds == other.bounds &&
        dpi == other.dpi;
  }

  @override
  int get hashCode => Object.hash(bounds, dpi);
}

final class WindowsWindowState {
  const WindowsWindowState({required this.placement, required this.maximized});

  final WindowsWindowPlacement placement;
  final bool maximized;

  @override
  bool operator ==(Object other) {
    return other is WindowsWindowState &&
        placement == other.placement &&
        maximized == other.maximized;
  }

  @override
  int get hashCode => Object.hash(placement, maximized);
}

abstract interface class WindowsWindowStateStore {
  Future<WindowsWindowState?> load({required String applicationIdentity});

  Future<void> save({
    required String applicationIdentity,
    required WindowsWindowState state,
  });
}
