import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/local/local_app_session_repository.dart';
import 'package:senior_companion/core/repositories/local/local_preferences_repository.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/models/app_user.dart';

class _InMemoryStorageService implements StorageService {
  final Map<String, Object> _data = <String, Object>{};

  @override
  Future<void> initialize() async {}

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => _data.remove(key) != null;
}

class _NoopLogger implements AppLogger {
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
  group('LocalPreferencesRepository', () {
    test('persists and retrieves preferred role and notifications flag',
        () async {
      final storage = _InMemoryStorageService();
      final repo = LocalPreferencesRepository(storage: storage);

      expect(await repo.getPreferredRole(), AppRole.senior);
      expect(await repo.isNotificationsEnabled(), isFalse);

      await repo.setPreferredRole(AppRole.guardian);
      await repo.setNotificationsEnabled(true);

      expect(await repo.getPreferredRole(), AppRole.guardian);
      expect(await repo.isNotificationsEnabled(), isTrue);
    });
  });

  group('LocalAppSessionRepository', () {
    test('saves, reads, and clears session from local storage', () async {
      final storage = _InMemoryStorageService();
      final repo = LocalAppSessionRepository(
        storage: storage,
        logger: _NoopLogger(),
      );

      const user = AppUser(
        id: 'u1',
        name: 'Demo User',
        role: AppRole.guardian,
      );
      final session = AppSession(
        user: user,
        activeRole: AppRole.guardian,
        startedAt: DateTime.parse('2026-04-18T10:00:00Z'),
      );

      await repo.saveSession(session);
      final loaded = await repo.getSession();
      expect(loaded, isNotNull);
      expect(loaded!.user.id, 'u1');
      expect(loaded.activeRole, AppRole.guardian);

      await repo.clearSession();
      expect(await repo.getSession(), isNull);
    });
  });
}
