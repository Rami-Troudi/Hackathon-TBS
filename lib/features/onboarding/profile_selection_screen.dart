import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/features/onboarding/onboarding_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
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
    if (!context.mounted) return;
    context.go(
        role == AppRole.senior ? AppRoutes.seniorHome : AppRoutes.guardianHome);
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
