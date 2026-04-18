import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

abstract class ProfileRepository {
  Future<List<SeniorProfile>> getSeniorProfiles();
  Future<List<GuardianProfile>> getGuardianProfiles();
  Future<SeniorProfile?> getSeniorProfileById(String id);
  Future<GuardianProfile?> getGuardianProfileById(String id);
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId);
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId);

  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles);
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles);
  Future<void> saveProfileLinks(List<ProfileLink> links);
  Future<void> clearAllProfiles();
}
