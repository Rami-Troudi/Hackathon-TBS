import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:senior_companion/core/repositories/local/local_demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/local/local_profile_repository.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
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
    final seedRepository = LocalDemoSeedRepository(
      profileRepository: profileRepository,
      storage: _InMemoryStorageService(),
    );

    await seedRepository.reseedDemoData();
    await seedRepository.resetDemoData();

    expect(await profileRepository.getSeniorProfiles(), isEmpty);
    expect(await profileRepository.getGuardianProfiles(), isEmpty);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
