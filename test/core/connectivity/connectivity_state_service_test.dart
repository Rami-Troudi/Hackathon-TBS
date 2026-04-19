import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

class _FakeStorageService implements StorageService {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  List<String>? getStringList(String key) => _values[key] as List<String>?;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> remove(String key) async => _values.remove(key) != null;

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _values[key] = value;
    return true;
  }
}

class _FakeLogger implements AppLogger {
  @override
  void debug(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}

  @override
  void warn(String message) {}
}

void main() {
  test('initializes from persisted connectivity state', () async {
    final storage = _FakeStorageService();
    await storage.setString(StorageKeys.connectivityState, 'offline');
    final service = LocalConnectivityStateService(
      storage: storage,
      logger: _FakeLogger(),
    );

    await service.initialize();

    expect(service.currentState, AppConnectivityState.offline);
    service.dispose();
  });

  test('setState persists and updates current state', () async {
    final storage = _FakeStorageService();
    final service = LocalConnectivityStateService(
      storage: storage,
      logger: _FakeLogger(),
    );
    await service.initialize();

    await service.setState(AppConnectivityState.degraded);

    expect(service.currentState, AppConnectivityState.degraded);
    expect(storage.getString(StorageKeys.connectivityState), 'degraded');
    service.dispose();
  });
}
