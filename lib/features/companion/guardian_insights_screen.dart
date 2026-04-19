import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class GuardianInsightsScreen extends StatelessWidget {
  const GuardianInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Insights',
      role: AppShellRole.guardian,
      currentRoute: AppRoutes.guardianInsights,
      child: ListView(
        children: [
          AppCard(
            tone: AppCardTone.sage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guardian AI is not active in this build',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Gaps.v8,
                Text(
                  'The only AI path now is the senior voice companion through the configured voice gateway. Guardian decisions continue to use deterministic local alerts, timeline, and summaries.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          Gaps.v16,
          MonitoringCard(
            title: 'Review active alerts',
            subtitle: 'Use local deterministic alert rules.',
            icon: Icons.notifications_active_outlined,
            onTap: () => context.push(AppRoutes.guardianAlerts),
          ),
          Gaps.v12,
          MonitoringCard(
            title: 'Open daily summary',
            subtitle: 'Read the rule-based local digest.',
            icon: Icons.summarize_outlined,
            onTap: () => context.push(AppRoutes.guardianSummary),
          ),
          Gaps.v12,
          MonitoringCard(
            title: 'Check timeline',
            subtitle: 'Inspect persisted local events.',
            icon: Icons.timeline_outlined,
            onTap: () => context.push(AppRoutes.guardianTimeline),
          ),
        ],
      ),
    );
  }
}
