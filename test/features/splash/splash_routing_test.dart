import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/app.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/core/repositories/preferences_repository.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/models/app_user.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class _FakePreferencesRepository implements PreferencesRepository {
  _FakePreferencesRepository({
    this.role = AppRole.senior,
  });

  AppRole role;
  bool notificationsEnabled = false;
  int launchCount = 0;

  @override
  Future<AppRole> getPreferredRole() async => role;

  @override
  Future<int> getLaunchCount() async => launchCount;

  @override
  Future<int> incrementLaunchCount() async {
    launchCount += 1;
    return launchCount;
  }

  @override
  Future<bool> isNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
  }

  @override
  Future<void> setPreferredRole(AppRole role) async {
    this.role = role;
  }
}

class _FakeSessionRepository implements AppSessionRepository {
  _FakeSessionRepository(this.session);

  AppSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<AppSession?> getSession() async => session;

  @override
  Future<void> saveSession(AppSession session) async {
    this.session = session;
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> fetchDashboardSummary() async {
    return DashboardSummary(
      globalStatus: SeniorGlobalStatus.ok,
      pendingAlerts: 0,
      todayCheckIns: 0,
      missedMedications: 0,
      openIncidents: 0,
    );
  }
}

void main() {
  testWidgets('routes to Home when there is no active session', (tester) async {
    final prefs = _FakePreferencesRepository(role: AppRole.guardian);
    final sessionRepo = _FakeSessionRepository(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesRepositoryProvider.overrideWithValue(prefs),
          appSessionRepositoryProvider.overrideWithValue(sessionRepo),
          dashboardRepositoryProvider
              .overrideWithValue(_FakeDashboardRepository()),
        ],
        child: const SeniorCompanionApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Prototype Foundation'), findsOneWidget);
  });

  testWidgets('routes to Senior screen when active role is senior',
      (tester) async {
    final prefs = _FakePreferencesRepository();
    final sessionRepo = _FakeSessionRepository(
      AppSession(
        user: const AppUser(
          id: 'senior-1',
          name: 'Senior Demo',
          role: AppRole.senior,
        ),
        activeRole: AppRole.senior,
        startedAt: DateTime.parse('2026-04-18T10:00:00Z'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesRepositoryProvider.overrideWithValue(prefs),
          appSessionRepositoryProvider.overrideWithValue(sessionRepo),
          dashboardRepositoryProvider
              .overrideWithValue(_FakeDashboardRepository()),
        ],
        child: const SeniorCompanionApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('Senior Home'), findsOneWidget);
    expect(find.text('Senior Home Placeholder'), findsOneWidget);
  });
}
