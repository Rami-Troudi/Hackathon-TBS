import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/safe_zone.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';

abstract class SafeZoneRepository {
  Future<List<SafeZone>> getSafeZonesForSenior(String seniorId);

  Future<void> saveSafeZone(SafeZone zone);

  Future<void> deleteSafeZone({
    required String seniorId,
    required String zoneId,
  });

  Future<void> seedDefaultZonesIfNeeded(String seniorId);

  Future<SafeZoneStatus> getCurrentStatus(String seniorId);

  Future<SafeZoneStatus> updateSimulatedLocation(
    String seniorId, {
    required double latitude,
    required double longitude,
    String? label,
    DateTime? now,
  });

  Future<List<PersistedEventRecord>> fetchRecentZoneEvents(
    String seniorId, {
    int limit,
  });
}
