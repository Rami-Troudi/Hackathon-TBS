import 'package:senior_companion/core/storage/hive_box_names.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  const LocalProfileRepository({
    required this.hiveInitializer,
  });

  final HiveInitializer hiveInitializer;

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async {
    final box = hiveInitializer.box(HiveBoxNames.seniorProfiles);
    return box.values
        .map(
            (entry) => SeniorProfile.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  @override
  Future<List<GuardianProfile>> getGuardianProfiles() async {
    final box = hiveInitializer.box(HiveBoxNames.guardianProfiles);
    return box.values
        .map(
          (entry) => GuardianProfile.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async {
    final box = hiveInitializer.box(HiveBoxNames.seniorProfiles);
    final entry = box.get(id);
    if (entry == null) return null;
    return SeniorProfile.fromJson(Map<String, dynamic>.from(entry));
  }

  @override
  Future<GuardianProfile?> getGuardianProfileById(String id) async {
    final box = hiveInitializer.box(HiveBoxNames.guardianProfiles);
    final entry = box.get(id);
    if (entry == null) return null;
    return GuardianProfile.fromJson(Map<String, dynamic>.from(entry));
  }

  @override
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId) async {
    final links = await _getLinks();
    final guardianIds = links
        .where((link) => link.seniorId == seniorId)
        .map((link) => link.guardianId)
        .toSet();
    final guardians = await getGuardianProfiles();
    return guardians
        .where((profile) => guardianIds.contains(profile.id))
        .toList();
  }

  @override
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId) async {
    final links = await _getLinks();
    final seniorIds = links
        .where((link) => link.guardianId == guardianId)
        .map((link) => link.seniorId)
        .toSet();
    final seniors = await getSeniorProfiles();
    return seniors.where((profile) => seniorIds.contains(profile.id)).toList();
  }

  @override
  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles) async {
    final box = hiveInitializer.box(HiveBoxNames.seniorProfiles);
    for (final profile in profiles) {
      await box.put(profile.id, profile.toJson());
    }
  }

  @override
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles) async {
    final box = hiveInitializer.box(HiveBoxNames.guardianProfiles);
    for (final profile in profiles) {
      await box.put(profile.id, profile.toJson());
    }
  }

  @override
  Future<void> saveProfileLinks(List<ProfileLink> links) async {
    final box = hiveInitializer.box(HiveBoxNames.profileLinks);
    for (final link in links) {
      await box.put(link.id, link.toJson());
    }
  }

  @override
  Future<void> clearAllProfiles() async {
    await hiveInitializer.box(HiveBoxNames.seniorProfiles).clear();
    await hiveInitializer.box(HiveBoxNames.guardianProfiles).clear();
    await hiveInitializer.box(HiveBoxNames.profileLinks).clear();
  }

  Future<List<ProfileLink>> _getLinks() async {
    final box = hiveInitializer.box(HiveBoxNames.profileLinks);
    return box.values
        .map((entry) => ProfileLink.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
