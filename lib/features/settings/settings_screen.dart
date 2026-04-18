import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/models/settings_preferences.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/feature_placeholder_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppPermissionStatus? _notificationPermissionStatus;
  AppPermissionStatus? _locationPermissionStatus;
  AppSession? _activeSession;
  SeniorSettingsPreferences? _seniorSettings;
  GuardianSettingsPreferences? _guardianSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  bool get _isSeniorRole => _activeSession?.activeRole == AppRole.senior;
  bool get _isGuardianRole => _activeSession?.activeRole == AppRole.guardian;

  Future<void> _loadSettings() async {
    final permissionService = ref.read(permissionServiceProvider);
    final sessionRepository = ref.read(appSessionRepositoryProvider);
    final settingsRepository = ref.read(settingsRepositoryProvider);

    final notificationStatus = await permissionService.notificationStatus();
    final locationStatus = await permissionService.locationStatus();
    final session = await sessionRepository.getSession();

    SeniorSettingsPreferences? seniorSettings;
    GuardianSettingsPreferences? guardianSettings;
    if (session != null) {
      if (session.activeRole == AppRole.senior) {
        seniorSettings =
            await settingsRepository.getSeniorSettings(session.activeProfileId);
      } else {
        guardianSettings = await settingsRepository
            .getGuardianSettings(session.activeProfileId);
      }
    }

    if (!mounted) return;
    setState(() {
      _notificationPermissionStatus = notificationStatus;
      _locationPermissionStatus = locationStatus;
      _activeSession = session;
      _seniorSettings = seniorSettings;
      _guardianSettings = guardianSettings;
    });
  }

  Future<void> _saveSenior(SeniorSettingsPreferences settings) async {
    final session = _activeSession;
    if (session == null || session.activeRole != AppRole.senior) return;
    await ref
        .read(settingsRepositoryProvider)
        .saveSeniorSettings(session.activeProfileId, settings);
    if (!mounted) return;
    setState(() => _seniorSettings = settings);
  }

  Future<void> _saveGuardian(GuardianSettingsPreferences settings) async {
    final session = _activeSession;
    if (session == null || session.activeRole != AppRole.guardian) return;
    await ref
        .read(settingsRepositoryProvider)
        .saveGuardianSettings(session.activeProfileId, settings);
    if (!mounted) return;
    setState(() => _guardianSettings = settings);
  }

  Future<void> _requestNotificationPermission() async {
    final notificationService = ref.read(notificationServiceProvider);
    final status = await notificationService.requestPermission();
    if (!mounted) return;
    setState(() {
      _notificationPermissionStatus = status;
    });
  }

  Future<void> _requestLocationPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.requestLocationPermission();
    if (!mounted) return;
    setState(() {
      _locationPermissionStatus = status;
    });
  }

  Future<void> _editEmergencyContactLabel(
    SeniorSettingsPreferences settings,
  ) async {
    final controller =
        TextEditingController(text: settings.emergencyContactLabel);
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency contact label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'Family contact',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (submitted == null || submitted.isEmpty) return;
    await _saveSenior(settings.copyWith(emergencyContactLabel: submitted));
  }

  Future<void> _clearSession() async {
    await ref.read(appSessionRepositoryProvider).clearSession();
    if (!mounted) return;
    setState(() {
      _activeSession = null;
      _seniorSettings = null;
      _guardianSettings = null;
    });
    context.go(AppRoutes.onboardingRole);
  }

  Future<void> _resetDemoData() async {
    await ref.read(demoSeedRepositoryProvider).resetDemoData();
    await ref.read(appSessionRepositoryProvider).clearSession();
    if (!mounted) return;
    setState(() {
      _activeSession = null;
      _seniorSettings = null;
      _guardianSettings = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo data reset complete')),
    );
    context.go(AppRoutes.onboardingRole);
  }

  Future<void> _reseedDemoData() async {
    await ref.read(demoSeedRepositoryProvider).reseedDemoData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo data reseeded')),
    );
  }

  Future<void> _switchRoleForTesting() async {
    final session = await ref.read(appSessionRepositoryProvider).getSession();
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active session to switch')),
      );
      return;
    }

    final nextRole = session.activeRole == AppRole.senior
        ? AppRole.guardian
        : AppRole.senior;
    final profileRepository = ref.read(profileRepositoryProvider);
    String? nextProfileId;

    if (session.activeRole == AppRole.senior) {
      final linkedGuardians = await profileRepository.getLinkedGuardians(
        session.activeProfileId,
      );
      if (linkedGuardians.isNotEmpty) {
        nextProfileId = linkedGuardians.first.id;
      } else {
        final allGuardians = await profileRepository.getGuardianProfiles();
        nextProfileId = allGuardians.isEmpty ? null : allGuardians.first.id;
      }
    } else {
      final linkedSeniors = await profileRepository.getLinkedSeniors(
        session.activeProfileId,
      );
      if (linkedSeniors.isNotEmpty) {
        nextProfileId = linkedSeniors.first.id;
      } else {
        final allSeniors = await profileRepository.getSeniorProfiles();
        nextProfileId = allSeniors.isEmpty ? null : allSeniors.first.id;
      }
    }

    if (nextProfileId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile available for target role')),
      );
      return;
    }

    await ref.read(appSessionRepositoryProvider).switchSessionRole(
          activeRole: nextRole,
          activeProfileId: nextProfileId,
        );
    await ref.read(preferencesRepositoryProvider).setPreferredRole(nextRole);
    await _loadSettings();
    if (!mounted) return;
    context.go(nextRole == AppRole.senior
        ? AppRoutes.seniorHome
        : AppRoutes.guardianHome);
  }

  List<Widget> _buildRoleSettings() {
    if (_isSeniorRole && _seniorSettings != null) {
      final settings = _seniorSettings!;
      return [
        Text('Senior preferences',
            style: Theme.of(context).textTheme.titleLarge),
        Gaps.v8,
        SwitchListTile(
          value: settings.largeTextEnabled,
          title: const Text('Large text'),
          onChanged: (value) =>
              _saveSenior(settings.copyWith(largeTextEnabled: value)),
        ),
        SwitchListTile(
          value: settings.highContrastEnabled,
          title: const Text('High contrast mode'),
          onChanged: (value) =>
              _saveSenior(settings.copyWith(highContrastEnabled: value)),
        ),
        SwitchListTile(
          value: settings.notificationsEnabled,
          title: const Text('Notifications enabled'),
          onChanged: (value) =>
              _saveSenior(settings.copyWith(notificationsEnabled: value)),
        ),
        SwitchListTile(
          value: settings.simplifiedModeEnabled,
          title: const Text('Simplified mode'),
          subtitle: const Text('Reduces visual density on senior home.'),
          onChanged: (value) =>
              _saveSenior(settings.copyWith(simplifiedModeEnabled: value)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reminder intensity'),
          trailing: DropdownButton<ReminderIntensity>(
            value: settings.reminderIntensity,
            onChanged: (value) {
              if (value == null) return;
              _saveSenior(settings.copyWith(reminderIntensity: value));
            },
            items: ReminderIntensity.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Language'),
          trailing: DropdownButton<String>(
            value: settings.languageCode,
            onChanged: (value) {
              if (value == null) return;
              _saveSenior(settings.copyWith(languageCode: value));
            },
            items: const [
              DropdownMenuItem(value: 'fr', child: Text('French')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('Arabic')),
            ],
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Emergency contact label'),
          subtitle: Text(settings.emergencyContactLabel),
          trailing: TextButton(
            onPressed: () => _editEmergencyContactLabel(settings),
            child: const Text('Edit'),
          ),
        ),
      ];
    }

    if (_isGuardianRole && _guardianSettings != null) {
      final settings = _guardianSettings!;
      return [
        Text('Guardian preferences',
            style: Theme.of(context).textTheme.titleLarge),
        Gaps.v8,
        SwitchListTile(
          value: settings.notificationsEnabled,
          title: const Text('Notifications enabled'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(notificationsEnabled: value)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Alert sensitivity'),
          trailing: DropdownButton<AlertSensitivity>(
            value: settings.alertSensitivity,
            onChanged: (value) {
              if (value == null) return;
              _saveGuardian(settings.copyWith(alertSensitivity: value));
            },
            items: AlertSensitivity.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        SwitchListTile(
          value: settings.dailyDigestEnabled,
          title: const Text('Daily digest'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(dailyDigestEnabled: value)),
        ),
        SwitchListTile(
          value: settings.weeklyDigestEnabled,
          title: const Text('Weekly digest'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(weeklyDigestEnabled: value)),
        ),
        SwitchListTile(
          value: settings.showMedicationReminders,
          title: const Text('Show medication monitoring'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(showMedicationReminders: value)),
        ),
        SwitchListTile(
          value: settings.showHydrationReminders,
          title: const Text('Show hydration monitoring'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(showHydrationReminders: value)),
        ),
        SwitchListTile(
          value: settings.showNutritionReminders,
          title: const Text('Show nutrition monitoring'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(showNutritionReminders: value)),
        ),
        SwitchListTile(
          value: settings.showLocationUpdates,
          title: const Text('Show location monitoring'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(showLocationUpdates: value)),
        ),
        SwitchListTile(
          value: settings.linkedSeniorInfoVisible,
          title: const Text('Show linked senior info'),
          onChanged: (value) =>
              _saveGuardian(settings.copyWith(linkedSeniorInfoVisible: value)),
        ),
      ];
    }

    return const [
      FeaturePlaceholderCard(
        icon: Icons.info_outline,
        title: 'Role preferences unavailable',
        description: 'Start a session from onboarding to configure settings.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shellRole =
        _isGuardianRole ? AppShellRole.guardian : AppShellRole.shared;
    return AppScaffoldShell(
      title: 'Settings',
      role: shellRole,
      currentRoute: AppRoutes.settings,
      child: ListView(
        children: [
          FeaturePlaceholderCard(
            icon: Icons.account_circle_outlined,
            title: 'Prototype session',
            description: _activeSession == null
                ? 'No active local session'
                : 'Role: ${_activeSession!.activeRole.label} • Profile: ${_activeSession!.activeProfileId}',
          ),
          Gaps.v16,
          ..._buildRoleSettings(),
          Gaps.v16,
          FeaturePlaceholderCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notification permission',
            description:
                'Status: ${_notificationPermissionStatus ?? 'unknown'}',
          ),
          Gaps.v8,
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            child: const Text('Request Notification Permission'),
          ),
          Gaps.v16,
          FeaturePlaceholderCard(
            icon: Icons.my_location_outlined,
            title: 'Location permission',
            description: 'Status: ${_locationPermissionStatus ?? 'unknown'}',
          ),
          Gaps.v8,
          ElevatedButton(
            onPressed: _requestLocationPermission,
            child: const Text('Request Location Permission'),
          ),
          Gaps.v24,
          Text('Developer tools',
              style: Theme.of(context).textTheme.titleMedium),
          Gaps.v8,
          ElevatedButton(
            onPressed: _switchRoleForTesting,
            child: const Text('Switch Role for Testing'),
          ),
          Gaps.v8,
          OutlinedButton(
            onPressed: _clearSession,
            child: const Text('Clear Session'),
          ),
          Gaps.v8,
          OutlinedButton(
            onPressed: _reseedDemoData,
            child: const Text('Reseed Demo Data'),
          ),
          Gaps.v8,
          OutlinedButton(
            onPressed: _resetDemoData,
            child: const Text('Reset Demo Data'),
          ),
        ],
      ),
    );
  }
}
