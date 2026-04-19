import 'package:senior_companion/core/repositories/preferences_repository.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/app_role.dart';

class LocalPreferencesRepository implements PreferencesRepository {
  const LocalPreferencesRepository({
    required this.storage,
  });

  final StorageService storage;

  @override
  Future<AppRole> getPreferredRole() async {
    final raw = storage.getString(StorageKeys.preferredRole);
    if (raw == null) return AppRole.senior;
    return AppRoleX.fromRaw(raw);
  }

  @override
  Future<void> setPreferredRole(AppRole role) async {
    await storage.setString(StorageKeys.preferredRole, role.value);
  }

  @override
  Future<int> getLaunchCount() async {
    return storage.getInt(StorageKeys.launchCount) ?? 0;
  }

  @override
  Future<int> incrementLaunchCount() async {
    final current = await getLaunchCount();
    final next = current + 1;
    await storage.setInt(StorageKeys.launchCount, next);
    return next;
  }

  @override
  Future<bool> isNotificationsEnabled() async {
    return storage.getBool(StorageKeys.notificationsEnabled) ?? false;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await storage.setBool(StorageKeys.notificationsEnabled, enabled);
  }
}
