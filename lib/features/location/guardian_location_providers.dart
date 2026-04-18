import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/safe_zone.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianLocationData {
  const GuardianLocationData({
    required this.seniorId,
    required this.seniorProfile,
    required this.zones,
    required this.status,
    required this.recentEvents,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final List<SafeZone> zones;
  final SafeZoneStatus status;
  final List<PersistedEventRecord> recentEvents;
}

final guardianLocationDataProvider =
    FutureProvider.autoDispose<GuardianLocationData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final safeZoneRepository = ref.watch(safeZoneRepositoryProvider);

  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianLocationData(
      seniorId: null,
      seniorProfile: null,
      zones: <SafeZone>[],
      status: SafeZoneStatus(
        location: null,
        activeZone: null,
        lastTransitionAt: null,
      ),
      recentEvents: <PersistedEventRecord>[],
    );
  }

  await safeZoneRepository.seedDefaultZonesIfNeeded(seniorId);
  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final zones = await safeZoneRepository.getSafeZonesForSenior(seniorId);
  final status = await safeZoneRepository.getCurrentStatus(seniorId);
  final recent = await safeZoneRepository.fetchRecentZoneEvents(
    seniorId,
    limit: 40,
  );
  return GuardianLocationData(
    seniorId: seniorId,
    seniorProfile: profile,
    zones: zones,
    status: status,
    recentEvents: recent,
  );
});
