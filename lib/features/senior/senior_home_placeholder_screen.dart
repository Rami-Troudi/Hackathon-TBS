import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/feature_placeholder_card.dart';

class SeniorHomePlaceholderScreen extends StatelessWidget {
  const SeniorHomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Senior Home',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.home),
          icon: const Icon(Icons.developer_mode_outlined),
          tooltip: 'Developer Hub',
        ),
      ],
      child: ListView(
        children: [
          const FeaturePlaceholderCard(
            icon: Icons.accessibility_new_outlined,
            title: 'Senior Home Placeholder',
            description:
                'Future senior-focused daily support modules (check-ins, reminders, simple actions) will be built here.',
          ),
          Gaps.v16,
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.home),
            icon: const Icon(Icons.developer_mode_outlined),
            label: const Text('Open Developer Hub (G2 event tools)'),
          ),
        ],
      ),
    );
  }
}
