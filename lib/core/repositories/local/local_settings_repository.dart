import 'dart:convert';

import 'package:senior_companion/core/repositories/settings_repository.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository({
    required this.storage,
  });

  final StorageService storage;

  @override
  Future<SeniorSettingsPreferences> getSeniorSettings(String seniorId) async {
    final raw = storage.getString(_seniorKey(seniorId));
    if (raw == null || raw.isEmpty) {
      return SeniorSettingsPreferences.defaults();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Senior settings payload must be a JSON map');
    }
    return SeniorSettingsPreferences.fromJson(decoded);
  }

  @override
  Future<void> saveSeniorSettings(
    String seniorId,
    SeniorSettingsPreferences preferences,
  ) async {
    final saved = await storage.setString(
      _seniorKey(seniorId),
      jsonEncode(preferences.toJson()),
    );
    if (!saved) {
      throw StateError('Failed to persist senior settings');
    }
  }

  @override
  Future<GuardianSettingsPreferences> getGuardianSettings(
    String guardianId,
  ) async {
    final raw = storage.getString(_guardianKey(guardianId));
    if (raw == null || raw.isEmpty) {
      return GuardianSettingsPreferences.defaults();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Guardian settings payload must be a JSON map');
    }
    return GuardianSettingsPreferences.fromJson(decoded);
  }

  @override
  Future<void> saveGuardianSettings(
    String guardianId,
    GuardianSettingsPreferences preferences,
  ) async {
    final saved = await storage.setString(
      _guardianKey(guardianId),
      jsonEncode(preferences.toJson()),
    );
    if (!saved) {
      throw StateError('Failed to persist guardian settings');
    }
  }

  String _seniorKey(String seniorId) =>
      '${StorageKeys.seniorSettingsPrefix}$seniorId';

  String _guardianKey(String guardianId) =>
      '${StorageKeys.guardianSettingsPrefix}$guardianId';
}
