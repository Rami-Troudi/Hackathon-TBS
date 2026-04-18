import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

final seniorProfilesProvider = FutureProvider<List<SeniorProfile>>((ref) {
  return ref.watch(profileRepositoryProvider).getSeniorProfiles();
});

final guardianProfilesProvider = FutureProvider<List<GuardianProfile>>((ref) {
  return ref.watch(profileRepositoryProvider).getGuardianProfiles();
});
