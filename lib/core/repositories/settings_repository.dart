import 'package:senior_companion/shared/models/settings_preferences.dart';

abstract class SettingsRepository {
  Future<SeniorSettingsPreferences> getSeniorSettings(String seniorId);

  Future<void> saveSeniorSettings(
    String seniorId,
    SeniorSettingsPreferences preferences,
  );

  Future<GuardianSettingsPreferences> getGuardianSettings(String guardianId);

  Future<void> saveGuardianSettings(
    String guardianId,
    GuardianSettingsPreferences preferences,
  );
}
