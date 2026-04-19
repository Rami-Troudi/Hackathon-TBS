abstract class DemoSeedRepository {
  Future<void> seedIfNeeded();
  Future<void> reseedDemoData();
  Future<void> resetDemoData();
}
