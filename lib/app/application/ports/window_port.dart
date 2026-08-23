abstract interface class WindowPort {
  Future<void> initialize();

  Future<void> open();

  Future<void> hide();

  Future<void> requestApplicationExit();

  Future<void> dispose();
}
