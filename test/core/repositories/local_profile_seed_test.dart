import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/repositories/local/local_demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/local/local_profile_repository.dart';
import 'package:senior_companion/core/storage/hive_box_names.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';

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

void main() {
  test('seed repository seeds deterministic demo profiles and links once',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('senior-companion-profile-seed');
    final hiveInitializer = HiveInitializer(
      hive: Hive,
      initFunction: () async {
        Hive.init(tempDir.path);
      },
    );
    await hiveInitializer.initialize();
    final profileRepository =
        LocalProfileRepository(hiveInitializer: hiveInitializer);
    final seedRepository = LocalDemoSeedRepository(
      profileRepository: profileRepository,
      storage: _InMemoryStorageService(),
      hiveInitializer: hiveInitializer,
    );

    await seedRepository.seedIfNeeded();
    await seedRepository.seedIfNeeded();

    final seniors = await profileRepository.getSeniorProfiles();
    final guardians = await profileRepository.getGuardianProfiles();
    final linkedGuardians =
        await profileRepository.getLinkedGuardians('senior-alice');

    expect(seniors, hasLength(2));
    expect(guardians, hasLength(2));
    expect(linkedGuardians.map((profile) => profile.id),
        contains('guardian-nour'));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('reset demo data clears structured profiles', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('senior-companion-profile-reset');
    final hiveInitializer = HiveInitializer(
      hive: Hive,
      initFunction: () async {
        Hive.init(tempDir.path);
      },
    );
    await hiveInitializer.initialize();
    final profileRepository =
        LocalProfileRepository(hiveInitializer: hiveInitializer);
    final storage = _InMemoryStorageService();
    await storage.setString(StorageKeys.appSession, 'stale-session');
    await storage.setString(StorageKeys.guardianAlertStates, '{"a":"active"}');
    await storage.setString(
      '${StorageKeys.seniorSettingsPrefix}senior-alice',
      '{}',
    );
    await storage.setString(
      '${StorageKeys.guardianSettingsPrefix}guardian-nour',
      '{}',
    );
    final seedRepository = LocalDemoSeedRepository(
      profileRepository: profileRepository,
      storage: storage,
      hiveInitializer: hiveInitializer,
    );

    await seedRepository.reseedDemoData();
    await hiveInitializer
        .box(HiveBoxNames.eventRecords)
        .put('event-1', {'id': 'event-1'});
    await hiveInitializer
        .box(HiveBoxNames.safeZoneState)
        .put('state-1', {'id': 'state-1'});
    await seedRepository.resetDemoData();

    expect(await profileRepository.getSeniorProfiles(), isEmpty);
    expect(await profileRepository.getGuardianProfiles(), isEmpty);
    expect(hiveInitializer.box(HiveBoxNames.eventRecords).isEmpty, isTrue);
    expect(hiveInitializer.box(HiveBoxNames.safeZoneState).isEmpty, isTrue);
    expect(storage.getString(StorageKeys.appSession), isNull);
    expect(storage.getString(StorageKeys.guardianAlertStates), isNull);
    expect(
      storage.getString('${StorageKeys.seniorSettingsPrefix}senior-alice'),
      isNull,
    );
    expect(
      storage.getString('${StorageKeys.guardianSettingsPrefix}guardian-nour'),
      isNull,
    );

    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('reseed demo data clears stale structured records before reseeding',
      () async {
    final tempDir = await Directory.systemTemp
        .createTemp('senior-companion-profile-reseed');
    final storage = _InMemoryStorageService();
    final hiveInitializer = HiveInitializer(
      hive: Hive,
      initFunction: () async {
        Hive.init(tempDir.path);
      },
    );
    await hiveInitializer.initialize();
    final profileRepository =
        LocalProfileRepository(hiveInitializer: hiveInitializer);
    final seedRepository = LocalDemoSeedRepository(
      profileRepository: profileRepository,
      storage: storage,
      hiveInitializer: hiveInitializer,
    );

    await seedRepository.reseedDemoData();
    await hiveInitializer
        .box(HiveBoxNames.eventRecords)
        .put('stale-event', {'id': 'stale-event'});
    await hiveInitializer
        .box(HiveBoxNames.safeZoneState)
        .put('stale-zone', {'id': 'stale-zone'});
    await storage.setString(StorageKeys.guardianAlertStates, '{"x":"active"}');

    await seedRepository.reseedDemoData();

    expect(hiveInitializer.box(HiveBoxNames.eventRecords).isEmpty, isTrue);
    expect(hiveInitializer.box(HiveBoxNames.safeZoneState).isEmpty, isTrue);
    expect(storage.getString(StorageKeys.guardianAlertStates), isNull);
    expect(await profileRepository.getSeniorProfiles(), hasLength(2));
    expect(await profileRepository.getGuardianProfiles(), hasLength(2));

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
