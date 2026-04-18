import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/repositories/local/local_settings_repository.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class _InMemoryStorageService implements StorageService {
  final Map<String, Object> _store = <String, Object>{};

  @override
  Future<void> initialize() async {}

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  double? getDouble(String key) => _store[key] as double?;

  @override
  int? getInt(String key) => _store[key] as int?;

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  List<String>? getStringList(String key) => _store[key] as List<String>?;

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return true;
  }
}

void main() {
  test('persists and restores senior settings by senior id', () async {
    final repository =
        LocalSettingsRepository(storage: _InMemoryStorageService());
    final seniorId = 'senior-a';
    final payload = SeniorSettingsPreferences.defaults().copyWith(
      largeTextEnabled: false,
      highContrastEnabled: true,
      reminderIntensity: ReminderIntensity.high,
      languageCode: 'en',
      emergencyContactLabel: 'Daughter',
      simplifiedModeEnabled: true,
    );

    await repository.saveSeniorSettings(seniorId, payload);
    final restored = await repository.getSeniorSettings(seniorId);

    expect(restored.largeTextEnabled, isFalse);
    expect(restored.highContrastEnabled, isTrue);
    expect(restored.reminderIntensity, ReminderIntensity.high);
    expect(restored.languageCode, 'en');
    expect(restored.emergencyContactLabel, 'Daughter');
    expect(restored.simplifiedModeEnabled, isTrue);
  });

  test('persists and restores guardian settings by guardian id', () async {
    final repository =
        LocalSettingsRepository(storage: _InMemoryStorageService());
    final guardianId = 'guardian-a';
    final payload = GuardianSettingsPreferences.defaults().copyWith(
      notificationsEnabled: false,
      alertSensitivity: AlertSensitivity.high,
      dailyDigestEnabled: false,
      weeklyDigestEnabled: true,
      showHydrationReminders: false,
      showNutritionReminders: false,
      showLocationUpdates: false,
      linkedSeniorInfoVisible: false,
    );

    await repository.saveGuardianSettings(guardianId, payload);
    final restored = await repository.getGuardianSettings(guardianId);

    expect(restored.notificationsEnabled, isFalse);
    expect(restored.alertSensitivity, AlertSensitivity.high);
    expect(restored.dailyDigestEnabled, isFalse);
    expect(restored.weeklyDigestEnabled, isTrue);
    expect(restored.showHydrationReminders, isFalse);
    expect(restored.showNutritionReminders, isFalse);
    expect(restored.showLocationUpdates, isFalse);
    expect(restored.linkedSeniorInfoVisible, isFalse);
  });
}
