import 'package:senior_companion/core/repositories/demo_seed_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

const _kDemoSeedVersion = 'g1-v1';

class LocalDemoSeedRepository implements DemoSeedRepository {
  const LocalDemoSeedRepository({
    required this.profileRepository,
    required this.storage,
  });

  final ProfileRepository profileRepository;
  final StorageService storage;

  @override
  Future<void> seedIfNeeded() async {
    final currentSeedVersion = storage.getString(StorageKeys.demoSeedVersion);
    final hasProfiles =
        (await profileRepository.getSeniorProfiles()).isNotEmpty &&
            (await profileRepository.getGuardianProfiles()).isNotEmpty;
    if (currentSeedVersion == _kDemoSeedVersion && hasProfiles) {
      return;
    }
    await reseedDemoData();
  }

  @override
  Future<void> reseedDemoData() async {
    await profileRepository.clearAllProfiles();
    await profileRepository.saveSeniorProfiles(_seedSeniors);
    await profileRepository.saveGuardianProfiles(_seedGuardians);
    await profileRepository.saveProfileLinks(_seedLinks);
    await storage.setString(StorageKeys.demoSeedVersion, _kDemoSeedVersion);
  }

  @override
  Future<void> resetDemoData() async {
    await profileRepository.clearAllProfiles();
    await storage.remove(StorageKeys.demoSeedVersion);
  }
}

const _seedSeniors = <SeniorProfile>[
  SeniorProfile(
    id: 'senior-alice',
    displayName: 'Alice Ben Salem',
    age: 74,
    preferredLanguage: 'fr',
    largeTextEnabled: true,
    highContrastEnabled: false,
    linkedGuardianIds: <String>['guardian-nour'],
  ),
  SeniorProfile(
    id: 'senior-mohamed',
    displayName: 'Mohamed Trabelsi',
    age: 79,
    preferredLanguage: 'ar',
    largeTextEnabled: true,
    highContrastEnabled: true,
    linkedGuardianIds: <String>['guardian-sami'],
  ),
];

const _seedGuardians = <GuardianProfile>[
  GuardianProfile(
    id: 'guardian-nour',
    displayName: 'Nour Ben Salem',
    relationshipLabel: 'Daughter',
    pushAlertNotificationsEnabled: true,
    dailySummaryEnabled: true,
    linkedSeniorIds: <String>['senior-alice'],
  ),
  GuardianProfile(
    id: 'guardian-sami',
    displayName: 'Sami Trabelsi',
    relationshipLabel: 'Son',
    pushAlertNotificationsEnabled: true,
    dailySummaryEnabled: false,
    linkedSeniorIds: <String>['senior-mohamed'],
  ),
];

const _seedLinks = <ProfileLink>[
  ProfileLink(
    id: 'link-alice-nour',
    seniorId: 'senior-alice',
    guardianId: 'guardian-nour',
  ),
  ProfileLink(
    id: 'link-mohamed-sami',
    seniorId: 'senior-mohamed',
    guardianId: 'guardian-sami',
  ),
];
