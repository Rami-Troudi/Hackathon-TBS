import 'package:senior_companion/shared/models/app_role.dart';

abstract class PreferencesRepository {
  Future<AppRole> getPreferredRole();
  Future<void> setPreferredRole(AppRole role);
  Future<int> getLaunchCount();
  Future<int> incrementLaunchCount();
  Future<bool> isNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
}
