import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
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
    required this.dashboardSummary,
  });

  /// How many times the app has been launched (incremented on each load).
  final int launchCount;

  /// The role currently preferred by the user (senior or guardian).
  /// Persisted in local storage and toggleable from the home screen.
  final AppRole preferredRole;

  /// A snapshot of the senior's current monitoring state.
  /// Sourced from [DashboardRepository] — mock in G0, real in G7+.
  final DashboardSummary dashboardSummary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeData &&
          other.launchCount == launchCount &&
          other.preferredRole == preferredRole &&
          other.dashboardSummary == dashboardSummary;

  @override
  int get hashCode => Object.hash(launchCount, preferredRole, dashboardSummary);

  @override
  String toString() => 'HomeData('
      'launchCount: $launchCount, '
      'preferredRole: $preferredRole, '
      'dashboardSummary: $dashboardSummary)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Loads all data needed by [HomeScreen] in a single async operation.
///
/// Uses [FutureProvider.autoDispose] so the data is re-fetched whenever
/// the provider is invalidated (e.g. after a role toggle via [ref.invalidate]).
///
/// ⚠️ Known prototype behaviour:
/// [incrementLaunchCount] is called every time this provider executes,
/// including on invalidation. This means toggling the role will increment
/// the launch count. This is acceptable for a demo prototype and should be
/// corrected in G1 by separating the one-time launch increment from the
/// role-refresh path.
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

  // Increment and read the launch count in a single operation.
  final launchCount = await preferencesRepo.incrementLaunchCount();

  // These two calls are independent — in the future they could be parallelised
  // with Future.wait if latency becomes a concern.
  final preferredRole = await preferencesRepo.getPreferredRole();
  final dashboardSummary = await dashboardRepo.fetchDashboardSummary();

  return HomeData(
    launchCount: launchCount,
    preferredRole: preferredRole,
    dashboardSummary: dashboardSummary,
  );
});