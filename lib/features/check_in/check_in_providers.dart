import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';

class CheckInData {
  const CheckInData({
    required this.seniorId,
    required this.checkInState,
    required this.recentCheckIns,
  });

  final String? seniorId;
  final CheckInState checkInState;
  final List<PersistedEventRecord> recentCheckIns;
}

final checkInDataProvider =
    FutureProvider.autoDispose<CheckInData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final repository = ref.watch(checkInRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  final now = DateTime.now();

  if (seniorId == null) {
    return CheckInData(
      seniorId: null,
      checkInState: CheckInState(
        status: CheckInStatus.pending,
        windowLabel: 'Daily morning check-in',
        windowStart: DateTime(now.year, now.month, now.day, 8),
        windowEnd: DateTime(now.year, now.month, now.day, 12),
      ),
      recentCheckIns: const <PersistedEventRecord>[],
    );
  }

  final state = await repository.getTodayState(
    seniorId,
    reconcileMissedWindow: true,
  );
  final recent = await repository.fetchRecentCheckIns(seniorId, limit: 7);

  return CheckInData(
    seniorId: seniorId,
    checkInState: state,
    recentCheckIns: recent,
  );
});
