import 'package:flutter/material.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/feature_placeholder_card.dart';

class SeniorHomePlaceholderScreen extends StatelessWidget {
  const SeniorHomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffoldShell(
      title: 'Senior Home',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeaturePlaceholderCard(
            icon: Icons.accessibility_new_outlined,
            title: 'Senior Home Placeholder',
            description:
                'Future senior-focused daily support modules (check-ins, reminders, simple actions) will be built here.',
          ),
        ],
      ),
    );
  }
}
