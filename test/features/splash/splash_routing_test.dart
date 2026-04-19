import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/app.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/repositories/dashboard_repository.dart';
import 'package:senior_companion/core/repositories/preferences_repository.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/repositories/settings_repository.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';

class _FakePreferencesRepository implements PreferencesRepository {
  _FakePreferencesRepository({
    this.role = AppRole.senior,
  });

  AppRole role;
  bool notificationsEnabled = false;
  int launchCount = 0;
  String languageCode = 'fr';

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

  @override
  Future<String> getAppLanguageCode() async => languageCode;

  @override
  Future<void> setAppLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
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
  Future<void> createSession({
    required AppRole activeRole,
    required String activeProfileId,
  }) async {
    session = AppSession(
      activeRole: activeRole,
      activeProfileId: activeProfileId,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveSession(AppSession session) async {
    this.session = session;
  }

  @override
  Future<void> switchSessionRole({
    required AppRole activeRole,
    required String activeProfileId,
  }) async {
    final existing = session;
    if (existing == null) return;
    session = AppSession(
      activeRole: activeRole,
      activeProfileId: activeProfileId,
      startedAt: existing.startedAt,
    );
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> fetchDashboardSummary({String? seniorId}) async {
    return DashboardSummary(
      globalStatus: SeniorGlobalStatus.ok,
      pendingAlerts: 0,
      todayCheckIns: 0,
      missedMedications: 0,
      openIncidents: 0,
    );
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<GuardianSettingsPreferences> getGuardianSettings(
      String guardianId) async {
    return GuardianSettingsPreferences.defaults();
  }

  @override
  Future<SeniorSettingsPreferences> getSeniorSettings(String seniorId) async {
    return SeniorSettingsPreferences.defaults();
  }

  @override
  Future<void> saveGuardianSettings(
      String guardianId, GuardianSettingsPreferences preferences) async {}

  @override
  Future<void> saveSeniorSettings(
      String seniorId, SeniorSettingsPreferences preferences) async {}
}

class _FakeStorageService implements StorageService {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  List<String>? getStringList(String key) => _values[key] as List<String>?;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _values[key] = value;
    return true;
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository();

  final _seniors = <SeniorProfile>[
    const SeniorProfile(
      id: 'senior-1',
      displayName: 'Senior Demo',
      age: 72,
      preferredLanguage: 'fr',
      largeTextEnabled: true,
      highContrastEnabled: false,
      linkedGuardianIds: <String>['guardian-1'],
    ),
  ];

  final _guardians = <GuardianProfile>[
    const GuardianProfile(
      id: 'guardian-1',
      displayName: 'Guardian Demo',
      relationshipLabel: 'Son',
      pushAlertNotificationsEnabled: true,
      dailySummaryEnabled: true,
      linkedSeniorIds: <String>['senior-1'],
    ),
  ];

  @override
  Future<void> clearAllProfiles() async {}

  @override
  Future<List<GuardianProfile>> getGuardianProfiles() async => _guardians;

  @override
  Future<GuardianProfile?> getGuardianProfileById(String id) async {
    for (final profile in _guardians) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  @override
  Future<List<GuardianProfile>> getLinkedGuardians(String seniorId) async {
    return _guardians
        .where((profile) => profile.linkedSeniorIds.contains(seniorId))
        .toList();
  }

  @override
  Future<List<SeniorProfile>> getLinkedSeniors(String guardianId) async {
    return _seniors
        .where((profile) => profile.linkedGuardianIds.contains(guardianId))
        .toList();
  }

  @override
  Future<List<SeniorProfile>> getSeniorProfiles() async => _seniors;

  @override
  Future<SeniorProfile?> getSeniorProfileById(String id) async {
    for (final profile in _seniors) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  @override
  Future<void> saveGuardianProfiles(List<GuardianProfile> profiles) async {}

  @override
  Future<void> saveProfileLinks(List<ProfileLink> links) async {}

  @override
  Future<void> saveSeniorProfiles(List<SeniorProfile> profiles) async {}
}

void main() {
  testWidgets(
      'routes to onboarding role selection when there is no active session',
      (tester) async {
    final prefs = _FakePreferencesRepository(role: AppRole.guardian);
    final sessionRepo = _FakeSessionRepository(null);
    final profileRepo = _FakeProfileRepository();
    final storage = _FakeStorageService();
    final settings = _FakeSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesRepositoryProvider.overrideWithValue(prefs),
          appSessionRepositoryProvider.overrideWithValue(sessionRepo),
          profileRepositoryProvider.overrideWithValue(profileRepo),
          storageServiceProvider.overrideWithValue(storage),
          settingsRepositoryProvider.overrideWithValue(settings),
          dashboardRepositoryProvider
              .overrideWithValue(_FakeDashboardRepository()),
        ],
        child: const SeniorCompanionApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Choose your prototype role'), findsOneWidget);
  });

  testWidgets('routes to Senior screen when active role is senior',
      (tester) async {
    final prefs = _FakePreferencesRepository();
    final sessionRepo = _FakeSessionRepository(
      AppSession(
        activeRole: AppRole.senior,
        activeProfileId: 'senior-1',
        startedAt: DateTime.parse('2026-04-18T10:00:00Z'),
      ),
    );
    final profileRepo = _FakeProfileRepository();
    final storage = _FakeStorageService();
    final settings = _FakeSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesRepositoryProvider.overrideWithValue(prefs),
          appSessionRepositoryProvider.overrideWithValue(sessionRepo),
          profileRepositoryProvider.overrideWithValue(profileRepo),
          storageServiceProvider.overrideWithValue(storage),
          settingsRepositoryProvider.overrideWithValue(settings),
          dashboardRepositoryProvider
              .overrideWithValue(_FakeDashboardRepository()),
        ],
        child: const SeniorCompanionApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Choose your prototype role'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('routes to Guardian screen when active role is guardian',
      (tester) async {
    final prefs = _FakePreferencesRepository(role: AppRole.guardian);
    final sessionRepo = _FakeSessionRepository(
      AppSession(
        activeRole: AppRole.guardian,
        activeProfileId: 'guardian-1',
        startedAt: DateTime.parse('2026-04-18T10:00:00Z'),
      ),
    );
    final profileRepo = _FakeProfileRepository();
    final storage = _FakeStorageService();
    final settings = _FakeSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesRepositoryProvider.overrideWithValue(prefs),
          appSessionRepositoryProvider.overrideWithValue(sessionRepo),
          profileRepositoryProvider.overrideWithValue(profileRepo),
          storageServiceProvider.overrideWithValue(storage),
          settingsRepositoryProvider.overrideWithValue(settings),
          dashboardRepositoryProvider
              .overrideWithValue(_FakeDashboardRepository()),
        ],
        child: const SeniorCompanionApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Choose your prototype role'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
