import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home data model
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregated data required to render the [HomeScreen].
///
/// This is a simple value class — no logic lives here. It exists solely
/// to group the three pieces of data the home screen needs into one type
/// so that [homeDataProvider] can return a single typed value.
class HomeData {
  const HomeData({
    required this.launchCount,
    required this.preferredRole,
    required this.activeSeniorId,
    required this.dashboardSummary,
    required this.recentEvents,
  });

  /// How many times the app has been launched (incremented on each load).
  final int launchCount;

  /// The role currently preferred by the user (senior or guardian).
  /// Persisted in local storage and toggleable from the home screen.
  final AppRole preferredRole;

  /// The senior profile currently driving summary/timeline in this session.
  final String? activeSeniorId;

  /// A snapshot of the senior's current monitoring state.
  /// Sourced from the local G2 event aggregation path.
  final DashboardSummary dashboardSummary;

  /// Recent persisted events in newest-first order for quick timeline preview.
  final List<PersistedEventRecord> recentEvents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeData &&
          other.launchCount == launchCount &&
          other.preferredRole == preferredRole &&
          other.activeSeniorId == activeSeniorId &&
          other.dashboardSummary == dashboardSummary &&
          _eventsEqual(other.recentEvents, recentEvents);

  @override
  int get hashCode => Object.hash(
        launchCount,
        preferredRole,
        activeSeniorId,
        dashboardSummary,
        Object.hashAll(recentEvents),
      );

  @override
  String toString() => 'HomeData('
      'launchCount: $launchCount, '
      'preferredRole: $preferredRole, '
      'activeSeniorId: $activeSeniorId, '
      'dashboardSummary: $dashboardSummary, '
      'recentEvents: ${recentEvents.length})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Loads all data needed by [HomeScreen] in a single async operation.
///
/// Uses [FutureProvider.autoDispose] so the data is re-fetched whenever
/// the provider is invalidated (e.g. after a role toggle via [ref.invalidate]).
///
/// Usage in a [ConsumerWidget]:
/// ```dart
/// final homeDataAsync = ref.watch(homeDataProvider);
/// homeDataAsync.when(
///   loading: () => const CircularProgressIndicator(),
///   error: (error, _) => Text('Failed to load'),
///   data: (homeData) => Text('Role: ${homeData.preferredRole.label}'),
/// );
/// ```
///
/// To force a refresh (e.g. after the user changes their role):
/// ```dart
/// ref.invalidate(homeDataProvider);
/// ```
final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final preferencesRepo = ref.watch(preferencesRepositoryProvider);
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final activeSeniorResolver = ref.watch(activeSeniorResolverProvider);

  // Launch count increment happens once in Splash startup.
  final launchCount = await preferencesRepo.getLaunchCount();

  final activeSeniorId = await activeSeniorResolver.resolveActiveSeniorId();

  final preferredRole = await preferencesRepo.getPreferredRole();
  final dashboardSummary = await dashboardRepo.fetchDashboardSummary(
    seniorId: activeSeniorId,
  );
  final recentEvents = activeSeniorId == null
      ? const <PersistedEventRecord>[]
      : await eventRepository.fetchRecentEventsForSenior(
          activeSeniorId,
          limit: 8,
        );

  return HomeData(
    launchCount: launchCount,
    preferredRole: preferredRole,
    activeSeniorId: activeSeniorId,
    dashboardSummary: dashboardSummary,
    recentEvents: recentEvents,
  );
});

bool _eventsEqual(
  List<PersistedEventRecord> left,
  List<PersistedEventRecord> right,
) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
