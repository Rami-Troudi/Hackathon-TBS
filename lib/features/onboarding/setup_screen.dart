import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/repositories/profile_repository.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/profile_link.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
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
  bool _linked = false;
  bool _seniorCheckInEnabled = true;
  bool _seniorMedicationEnabled = true;
  bool _seniorCompanionEnabled = true;
  bool _seniorIncidentEnabled = true;
  bool _guardianCheckInEnabled = true;
  bool _guardianMedicationEnabled = true;
  bool _guardianIncidentEnabled = true;
  bool _guardianHydrationEnabled = true;
  bool _guardianNutritionEnabled = true;
  bool _guardianLocationEnabled = true;
  bool _guardianSummaryEnabled = true;
  bool _guardianInsightsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final preferences = ref.read(preferencesRepositoryProvider);
    final settingsRepository = ref.read(settingsRepositoryProvider);
    final language = await preferences.getAppLanguageCode();
    if (widget.role == AppRole.senior) {
      final settings =
          await settingsRepository.getSeniorSettings(widget.profileId);
      _seniorCheckInEnabled = settings.checkInModuleEnabled;
      _seniorMedicationEnabled = settings.medicationModuleEnabled;
      _seniorCompanionEnabled = settings.companionModuleEnabled;
      _seniorIncidentEnabled = settings.incidentModuleEnabled;
    } else {
      final settings =
          await settingsRepository.getGuardianSettings(widget.profileId);
      _guardianCheckInEnabled = settings.showCheckInMonitoring;
      _guardianMedicationEnabled = settings.showMedicationReminders;
      _guardianIncidentEnabled = settings.showIncidentMonitoring;
      _guardianHydrationEnabled = settings.showHydrationReminders;
      _guardianNutritionEnabled = settings.showNutritionReminders;
      _guardianLocationEnabled = settings.showLocationUpdates;
      _guardianSummaryEnabled = settings.dailyDigestEnabled;
      _guardianInsightsEnabled = settings.showInsightsModule;
    }
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
        current.copyWith(
          languageCode: _languageCode,
          checkInModuleEnabled: _seniorCheckInEnabled,
          medicationModuleEnabled: _seniorMedicationEnabled,
          companionModuleEnabled: _seniorCompanionEnabled,
          incidentModuleEnabled: _seniorIncidentEnabled,
        ),
      );
    } else {
      final current =
          await settingsRepository.getGuardianSettings(widget.profileId);
      await settingsRepository.saveGuardianSettings(
        widget.profileId,
        current.copyWith(
          showCheckInMonitoring: _guardianCheckInEnabled,
          showMedicationReminders: _guardianMedicationEnabled,
          showIncidentMonitoring: _guardianIncidentEnabled,
          showHydrationReminders: _guardianHydrationEnabled,
          showNutritionReminders: _guardianNutritionEnabled,
          showLocationUpdates: _guardianLocationEnabled,
          dailyDigestEnabled: _guardianSummaryEnabled,
          showInsightsModule: _guardianInsightsEnabled,
        ),
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

  String _pairingCodeFor(String profileId) {
    final normalized = profileId.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return normalized.length <= 8
        ? normalized.padRight(8, 'X')
        : normalized.substring(0, 8);
  }

  Future<void> _linkPhoneFlow() async {
    final profileRepository = ref.read(profileRepositoryProvider);
    final codeController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Link phone'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Pairing code',
            hintText: 'Enter the other phone code',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Link'),
          ),
        ],
      ),
    );

    if (submitted != true) return;
    final code = codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final seniors = await profileRepository.getSeniorProfiles();
    final guardians = await profileRepository.getGuardianProfiles();
    final links = <ProfileLink>[];

    final linkedSenior = widget.role == AppRole.guardian
        ? _firstWhereOrNull(seniors, (p) => _pairingCodeFor(p.id) == code)
        : _firstWhereOrNull(seniors, (p) => p.id == widget.profileId);
    final linkedGuardian = widget.role == AppRole.senior
        ? _firstWhereOrNull(guardians, (p) => _pairingCodeFor(p.id) == code)
        : _firstWhereOrNull(guardians, (p) => p.id == widget.profileId);

    if (linkedSenior == null || linkedGuardian == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid pairing code')),
      );
      return;
    }

    final existingLinks = await _getAllLinks(profileRepository);
    final alreadyLinked = existingLinks.any(
      (l) => l.seniorId == linkedSenior.id && l.guardianId == linkedGuardian.id,
    );
    if (!alreadyLinked) {
      links.addAll(existingLinks);
      links.add(
        ProfileLink(
          id: 'link-${linkedSenior.id}-${linkedGuardian.id}',
          seniorId: linkedSenior.id,
          guardianId: linkedGuardian.id,
        ),
      );
      await profileRepository.saveProfileLinks(links);
    }

    final updatedSenior = SeniorProfile(
      id: linkedSenior.id,
      displayName: linkedSenior.displayName,
      age: linkedSenior.age,
      preferredLanguage: linkedSenior.preferredLanguage,
      largeTextEnabled: linkedSenior.largeTextEnabled,
      highContrastEnabled: linkedSenior.highContrastEnabled,
      linkedGuardianIds: _mergeIds(
        linkedSenior.linkedGuardianIds,
        linkedGuardian.id,
      ),
    );
    final updatedGuardian = GuardianProfile(
      id: linkedGuardian.id,
      displayName: linkedGuardian.displayName,
      relationshipLabel: linkedGuardian.relationshipLabel,
      pushAlertNotificationsEnabled: linkedGuardian.pushAlertNotificationsEnabled,
      dailySummaryEnabled: linkedGuardian.dailySummaryEnabled,
      linkedSeniorIds: _mergeIds(
        linkedGuardian.linkedSeniorIds,
        linkedSenior.id,
      ),
    );

    await profileRepository.saveSeniorProfiles([
      ...seniors.where((p) => p.id != linkedSenior.id),
      updatedSenior,
    ]);
    await profileRepository.saveGuardianProfiles([
      ...guardians.where((p) => p.id != linkedGuardian.id),
      updatedGuardian,
    ]);

    if (!mounted) return;
    setState(() => _linked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phones linked successfully')),
    );
  }

  List<String> _mergeIds(List<String> existing, String id) {
    if (existing.contains(id)) return existing;
    return [...existing, id];
  }

  Future<List<ProfileLink>> _getAllLinks(ProfileRepository repository) async {
    final seniors = await repository.getSeniorProfiles();
    final links = <ProfileLink>[];
    for (final senior in seniors) {
      final guardians = await repository.getLinkedGuardians(senior.id);
      for (final guardian in guardians) {
        links.add(
          ProfileLink(
            id: 'link-${senior.id}-${guardian.id}',
            seniorId: senior.id,
            guardianId: guardian.id,
          ),
        );
      }
    }
    return links;
  }

  T? _firstWhereOrNull<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This phone pairing code'),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pairingCodeFor(widget.profileId),
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      onPressed: _linkPhoneFlow,
                      child: Text(_linked ? 'Linked' : 'Link phone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Enabled modules',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (widget.role == AppRole.senior) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _seniorCheckInEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _seniorCheckInEnabled = value);
              },
              title: const Text('Check-in'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _seniorMedicationEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _seniorMedicationEnabled = value);
              },
              title: const Text('Medication reminders'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _seniorCompanionEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _seniorCompanionEnabled = value);
              },
              title: const Text('AI companion'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _seniorIncidentEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _seniorIncidentEnabled = value);
              },
              title: const Text('Incident detection/help'),
            ),
          ] else ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianCheckInEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianCheckInEnabled = value);
              },
              title: const Text('Check-in monitoring'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianMedicationEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianMedicationEnabled = value);
              },
              title: const Text('Medication monitoring'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianIncidentEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianIncidentEnabled = value);
              },
              title: const Text('Incident monitoring'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianHydrationEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianHydrationEnabled = value);
              },
              title: const Text('Hydration monitoring'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianNutritionEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianNutritionEnabled = value);
              },
              title: const Text('Nutrition monitoring'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianLocationEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianLocationEnabled = value);
              },
              title: const Text('Location monitoring'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianSummaryEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianSummaryEnabled = value);
              },
              title: const Text('Daily digest'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _guardianInsightsEnabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _guardianInsightsEnabled = value);
              },
              title: const Text('AI insights'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
