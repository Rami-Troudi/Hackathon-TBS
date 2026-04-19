import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/features/onboarding/onboarding_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/guardian_profile.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({
    super.key,
    required this.role,
  });

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileListAsync = role == AppRole.senior
        ? ref.watch(seniorProfilesProvider).whenData(
              (profiles) => profiles
                  .map(
                    (profile) => _ProfileListItem(
                      id: profile.id,
                      title: profile.displayName,
                      subtitle:
                          '${profile.age} years • ${profile.preferredLanguage.toUpperCase()}',
                    ),
                  )
                  .toList(),
            )
        : ref.watch(guardianProfilesProvider).whenData(
              (profiles) => profiles
                  .map(
                    (profile) => _ProfileListItem(
                      id: profile.id,
                      title: profile.displayName,
                      subtitle: profile.relationshipLabel,
                    ),
                  )
                  .toList(),
            );

    return AppScaffoldShell(
      title: 'Choose Profile',
      child: profileListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (profiles) => ListView(
          children: [
            Text(
              role == AppRole.senior
                  ? 'Select a senior demo profile'
                  : 'Select a guardian demo profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Gaps.v8,
            Text(
              'Your selection will create a local prototype session.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v16,
            ...profiles.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProfileCard(
                  profile: profile,
                  onTap: () => _selectProfile(context, ref, profile.id),
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _createProfile(context, ref),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(
                role == AppRole.senior
                    ? 'Create senior profile'
                    : 'Create guardian profile',
              ),
            ),
            Gaps.v8,
            TextButton(
              onPressed: () => context.go(AppRoutes.onboardingRole),
              child: const Text('Back to role selection'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectProfile(
    BuildContext context,
    WidgetRef ref,
    String profileId,
  ) async {
    final sessionRepository = ref.read(appSessionRepositoryProvider);
    final preferencesRepository = ref.read(preferencesRepositoryProvider);
    await sessionRepository.createSession(
      activeRole: role,
      activeProfileId: profileId,
    );
    await preferencesRepository.setPreferredRole(role);
    await ref
        .read(storageServiceProvider)
        .setBool('${StorageKeys.onboardingSetupDonePrefix}$profileId', false);
    if (!context.mounted) return;
    context.go(
      AppRoutes.onboardingSetupFor(
        role: role,
        profileId: profileId,
      ),
    );
  }

  Future<void> _createProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (role == AppRole.senior) {
      await _createSeniorProfile(context, ref);
    } else {
      await _createGuardianProfile(context, ref);
    }
  }

  Future<void> _createSeniorProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final ageController = TextEditingController(text: '72');
    String language = 'fr';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) => AlertDialog(
            title: const Text('Create senior profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: language,
                    items: const [
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => language = value);
                    },
                    decoration:
                        const InputDecoration(labelText: 'Preferred language'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
    if (submitted != true) return;

    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim()) ?? 72;
    if (name.isEmpty) return;

    final repository = ref.read(profileRepositoryProvider);
    final seniors = await repository.getSeniorProfiles();
    final id = 'senior-${DateTime.now().millisecondsSinceEpoch}';
    final created = SeniorProfile(
      id: id,
      displayName: name,
      age: age,
      preferredLanguage: language,
      largeTextEnabled: true,
      highContrastEnabled: false,
      linkedGuardianIds: const [],
    );
    await repository.saveSeniorProfiles([...seniors, created]);
    ref.invalidate(seniorProfilesProvider);
  }

  Future<void> _createGuardianProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController(text: 'Family');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create guardian profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (submitted != true) return;

    final name = nameController.text.trim();
    final relationship = relationshipController.text.trim();
    if (name.isEmpty || relationship.isEmpty) return;

    final repository = ref.read(profileRepositoryProvider);
    final guardians = await repository.getGuardianProfiles();
    final id = 'guardian-${DateTime.now().millisecondsSinceEpoch}';
    final created = GuardianProfile(
      id: id,
      displayName: name,
      relationshipLabel: relationship,
      pushAlertNotificationsEnabled: true,
      dailySummaryEnabled: true,
      linkedSeniorIds: const [],
    );
    await repository.saveGuardianProfiles([...guardians, created]);
    ref.invalidate(guardianProfilesProvider);
  }
}

class _ProfileListItem {
  const _ProfileListItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onTap,
  });

  final _ProfileListItem profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(profile.title),
        subtitle: Text(profile.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }
}
