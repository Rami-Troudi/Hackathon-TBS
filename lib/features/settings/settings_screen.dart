import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferencesRepository = ref.read(preferencesRepositoryProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final enabled = await preferencesRepository.isNotificationsEnabled();
    final notificationStatus = await permissionService.notificationStatus();
    final locationStatus = await permissionService.locationStatus();

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _notificationPermissionStatus = notificationStatus;
      _locationPermissionStatus = locationStatus;
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
            description: 'Status: ${_notificationPermissionStatus ?? 'unknown'}',
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
        ],
      ),
    );
  }
}
