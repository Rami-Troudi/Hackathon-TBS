import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _openRoleFlow(BuildContext context, AppRole role) {
    context.go(AppRoutes.onboardingProfileForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Welcome',
      child: ListView(
        children: [
          Text(
            'Choose your prototype role',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Gaps.v8,
          Text(
            'This local onboarding flow creates a demo session on this device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Gaps.v24,
          _RoleActionCard(
            icon: Icons.accessibility_new_outlined,
            title: 'Continue as Senior',
            subtitle: 'Simple daily support experience with low cognitive load',
            onTap: () => _openRoleFlow(context, AppRole.senior),
          ),
          Gaps.v16,
          _RoleActionCard(
            icon: Icons.family_restroom_outlined,
            title: 'Continue as Guardian',
            subtitle:
                'Monitoring and coordination experience for family members',
            onTap: () => _openRoleFlow(context, AppRole.guardian),
          ),
          Gaps.v24,
          TextButton(
            onPressed: () => context.push(AppRoutes.home),
            child: const Text('Open developer demo hub'),
          ),
        ],
      ),
    );
  }
}

class _RoleActionCard extends StatelessWidget {
  const _RoleActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: 36),
          Gaps.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Gaps.v4,
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 18),
        ],
      ),
    );
  }
}
