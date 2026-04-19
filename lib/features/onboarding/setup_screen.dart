import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class OnboardingSetupScreen extends ConsumerStatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.role,
    required this.profileId,
  });

  final AppRole role;
  final String profileId;

  @override
  ConsumerState<OnboardingSetupScreen> createState() =>
      _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends ConsumerState<OnboardingSetupScreen> {
  String _languageCode = 'fr';
  bool _notificationsGranted = false;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final preferences = ref.read(preferencesRepositoryProvider);
    final language = await preferences.getAppLanguageCode();
    if (!mounted) return;
    setState(() => _languageCode = language);
  }

  Future<void> _requestNotifications() async {
    final status = await ref.read(notificationServiceProvider).requestPermission();
    if (!mounted) return;
    setState(() => _notificationsGranted = status.name == 'granted');
  }

  Future<void> _requestLocation() async {
    final status =
        await ref.read(permissionServiceProvider).requestLocationPermission();
    if (!mounted) return;
    setState(() => _locationGranted = status.name == 'granted');
  }

  Future<void> _finishSetup() async {
    final storage = ref.read(storageServiceProvider);
    final preferences = ref.read(preferencesRepositoryProvider);
    final settingsRepository = ref.read(settingsRepositoryProvider);

    await preferences.setAppLanguageCode(_languageCode);
    if (widget.role == AppRole.senior) {
      final current =
          await settingsRepository.getSeniorSettings(widget.profileId);
      await settingsRepository.saveSeniorSettings(
        widget.profileId,
        current.copyWith(languageCode: _languageCode),
      );
    }

    await storage.setBool(
      '${StorageKeys.onboardingSetupDonePrefix}${widget.profileId}',
      true,
    );
    ref.read(appPresentationSettingsRevisionProvider.notifier).state++;
    if (!mounted) return;
    context.go(
      widget.role == AppRole.senior
          ? AppRoutes.seniorHome
          : AppRoutes.guardianHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Setup',
      child: ListView(
        children: [
          Text(
            'Device setup',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose language and enable permissions before using the app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _languageCode,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _languageCode = value);
              },
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _requestNotifications,
            child: Text(
              _notificationsGranted
                  ? 'Notifications granted'
                  : 'Allow notifications',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: _requestLocation,
            child: Text(
              _locationGranted ? 'Location granted' : 'Allow location',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _finishSetup,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
