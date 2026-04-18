import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/feature_placeholder_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = false;
  AppPermissionStatus? _notificationPermissionStatus;
  AppPermissionStatus? _locationPermissionStatus;
  AppSession? _activeSession;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferencesRepository = ref.read(preferencesRepositoryProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final sessionRepository = ref.read(appSessionRepositoryProvider);
    final enabled = await preferencesRepository.isNotificationsEnabled();
    final notificationStatus = await permissionService.notificationStatus();
    final locationStatus = await permissionService.locationStatus();
    final session = await sessionRepository.getSession();

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _notificationPermissionStatus = notificationStatus;
      _locationPermissionStatus = locationStatus;
      _activeSession = session;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final preferencesRepository = ref.read(preferencesRepositoryProvider);
    await preferencesRepository.setNotificationsEnabled(value);
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = value;
    });
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

  Future<void> _clearSession() async {
    await ref.read(appSessionRepositoryProvider).clearSession();
    if (!mounted) return;
    setState(() {
      _activeSession = null;
    });
    context.go(AppRoutes.onboardingRole);
  }

  Future<void> _resetDemoData() async {
    await ref.read(demoSeedRepositoryProvider).resetDemoData();
    await ref.read(appSessionRepositoryProvider).clearSession();
    if (!mounted) return;
    setState(() {
      _activeSession = null;
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
    if (nextRole == AppRole.senior) {
      final profiles = await profileRepository.getSeniorProfiles();
      nextProfileId = profiles.isEmpty ? null : profiles.first.id;
    } else {
      final profiles = await profileRepository.getGuardianProfiles();
      nextProfileId = profiles.isEmpty ? null : profiles.first.id;
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
    if (!mounted) return;
    context.go(nextRole == AppRole.senior
        ? AppRoutes.seniorHome
        : AppRoutes.guardianHome);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Settings',
      child: ListView(
        children: [
          SwitchListTile(
            value: _notificationsEnabled,
            title: const Text('Enable prototype notifications'),
            subtitle: const Text('Stored locally in lightweight preferences'),
            onChanged: _toggleNotifications,
          ),
          Gaps.v8,
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
          Gaps.v16,
          FeaturePlaceholderCard(
            icon: Icons.account_circle_outlined,
            title: 'Prototype session',
            description: _activeSession == null
                ? 'No active local session'
                : 'Role: ${_activeSession!.activeRole.label} • Profile: ${_activeSession!.activeProfileId}',
          ),
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
