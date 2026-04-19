import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/app/bootstrap/app_initializer.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/notifications/notification_service.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/core/repositories/demo_seed_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
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
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  bool? getBool(String key) => _values[key] as bool?;

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
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

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

class _FakeHiveInitializer extends HiveInitializer {
  _FakeHiveInitializer()
      : super(
          initFunction: () async {},
        );

  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }
}

class _FakeDemoSeedRepository implements DemoSeedRepository {
  bool seeded = false;

  @override
  Future<void> resetDemoData() async {}

  @override
  Future<void> reseedDemoData() async {}

  @override
  Future<void> seedIfNeeded() async {
    seeded = true;
  }
}

class _FakePermissionService implements PermissionService {
  int notificationRequests = 0;
  int locationRequests = 0;

  @override
  Future<AppPermissionStatus> locationStatus() async =>
      AppPermissionStatus.denied;

  @override
  Future<AppPermissionStatus> notificationStatus() async =>
      AppPermissionStatus.denied;

  @override
  Future<bool> openSystemSettings() async => true;

  @override
  Future<AppPermissionStatus> requestLocationPermission() async {
    locationRequests += 1;
    return AppPermissionStatus.granted;
  }

  @override
  Future<AppPermissionStatus> requestNotificationPermission() async {
    notificationRequests += 1;
    return AppPermissionStatus.granted;
  }
}

void main() {
  test('AppInitializer initializes storage, Hive, seeding, and notifications',
      () async {
    final logger = _FakeLogger();
    final storage = _FakeStorageService();
    final hiveInitializer = _FakeHiveInitializer();
    final demoSeedRepository = _FakeDemoSeedRepository();
    final notifications = _FakeNotificationService();
    final permissions = _FakePermissionService();

    final initializer = AppInitializer(
      logger: logger,
      storageService: storage,
      hiveInitializer: hiveInitializer,
      demoSeedRepository: demoSeedRepository,
      notificationService: notifications,
      permissionService: permissions,
    );

    await initializer.initialize();

    expect(storage.initialized, isTrue);
    expect(hiveInitializer.initialized, isTrue);
    expect(demoSeedRepository.seeded, isTrue);
    expect(notifications.initialized, isTrue);
    expect(permissions.notificationRequests, 1);
    expect(permissions.locationRequests, 1);
    expect(
      logger.infoLogs,
      containsAllInOrder(<String>[
        'Initializing storage service',
        'Initializing Hive structured storage',
        'Seeding local demo data if needed',
        'Initializing local notification service',
      ]),
    );
  });
}
