import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/app/bootstrap/app_initializer.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

class _FakeLogger implements AppLogger {
  final List<String> infoLogs = <String>[];

  @override
  void debug(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) => infoLogs.add(message);

  @override
  void warn(String message) {}
}

class _FakeStorageService implements StorageService {
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  bool? getBool(String key) => null;

  @override
  double? getDouble(String key) => null;

  @override
  int? getInt(String key) => null;

  @override
  String? getString(String key) => null;

  @override
  List<String>? getStringList(String key) => null;

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setBool(String key, bool value) async => true;

  @override
  Future<bool> setDouble(String key, double value) async => true;

  @override
  Future<bool> setInt(String key, int value) async => true;

  @override
  Future<bool> setString(String key, String value) async => true;

  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
}

class _FakeNotificationService implements NotificationService {
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<AppPermissionStatus> requestPermission() async =>
      AppPermissionStatus.granted;

  @override
  Future<void> showCritical(
      {required String title, required String body}) async {}

  @override
  Future<void> showInfo({required String title, required String body}) async {}

  @override
  Future<void> showWarning(
      {required String title, required String body}) async {}
}

void main() {
  test('AppInitializer initializes storage and notifications', () async {
    final logger = _FakeLogger();
    final storage = _FakeStorageService();
    final notifications = _FakeNotificationService();

    final initializer = AppInitializer(
      logger: logger,
      storageService: storage,
      notificationService: notifications,
    );

    await initializer.initialize();

    expect(storage.initialized, isTrue);
    expect(notifications.initialized, isTrue);
    expect(
      logger.infoLogs,
      containsAllInOrder(<String>[
        'Initializing storage service',
        'Initializing local notification service',
      ]),
    );
  });
}
