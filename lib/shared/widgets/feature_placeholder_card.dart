import 'package:flutter/material.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';

class FeaturePlaceholderCard extends StatelessWidget {
  const FeaturePlaceholderCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.extension_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
