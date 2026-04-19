import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/shared/models/guardian_timeline_filter.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class GuardianTimelineData {
  const GuardianTimelineData({
    required this.seniorId,
    required this.seniorProfile,
    required this.events,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final List<PersistedEventRecord> events;

  List<PersistedEventRecord> forFilter(GuardianTimelineFilter filter) {
    final types = filter.eventTypes;
    if (types == null) return events;
    return events.where((event) => types.contains(event.type)).toList();
  }
}

final guardianTimelineFilterProvider =
    StateProvider.autoDispose<GuardianTimelineFilter>(
  (_) => GuardianTimelineFilter.all,
);

final guardianTimelineDataProvider =
    FutureProvider.autoDispose<GuardianTimelineData>((ref) async {
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);

  final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return const GuardianTimelineData(
      seniorId: null,
      seniorProfile: null,
      events: <PersistedEventRecord>[],
    );
  }

  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final events = await eventRepository.fetchTimelineForSenior(
    seniorId,
    order: TimelineOrder.newestFirst,
    limit: 250,
  );

  return GuardianTimelineData(
    seniorId: seniorId,
    seniorProfile: profile,
    events: events,
  );
});

final guardianFilteredTimelineProvider =
    Provider.autoDispose<AsyncValue<List<PersistedEventRecord>>>((ref) {
  final timelineDataAsync = ref.watch(guardianTimelineDataProvider);
  final filter = ref.watch(guardianTimelineFilterProvider);
  return timelineDataAsync.whenData((data) => data.forFilter(filter));
});
