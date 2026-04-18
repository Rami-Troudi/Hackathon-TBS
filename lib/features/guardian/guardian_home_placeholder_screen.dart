import 'package:flutter/material.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/feature_placeholder_card.dart';

class GuardianHomePlaceholderScreen extends StatelessWidget {
  const GuardianHomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffoldShell(
      title: 'Guardian Home',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeaturePlaceholderCard(
            icon: Icons.family_restroom_outlined,
            title: 'Guardian Home Placeholder',
            description:
                'Future guardian monitoring and coordination modules will be built in this space.',
          ),
        ],
      ),
    );
  }
}
