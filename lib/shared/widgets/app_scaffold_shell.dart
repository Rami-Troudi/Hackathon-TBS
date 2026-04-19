import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_colors.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/localization/app_tr.dart';

enum AppShellRole {
  senior,
  guardian,
  shared,
}

class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.role = AppShellRole.shared,
    this.currentRoute,
    this.backgroundColor,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final AppShellRole role;
  final String? currentRoute;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final showGuardianNav = role == AppShellRole.guardian;
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
      bottomNavigationBar: showGuardianNav
          ? _GuardianBottomNav(currentRoute: currentRoute)
          : null,
    );
  }
}

class _GuardianBottomNav extends StatelessWidget {
  const _GuardianBottomNav({
    this.currentRoute,
  });

  final String? currentRoute;

  static const _routes = <String>[
    AppRoutes.guardianHome,
    AppRoutes.guardianAlerts,
    AppRoutes.guardianTimeline,
    AppRoutes.guardianSummary,
    AppRoutes.settings,
  ];

  int _selectedIndex(BuildContext context) {
    final location = currentRoute ?? GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.guardianAlerts)) return 1;
    if (location.startsWith(AppRoutes.guardianTimeline)) return 2;
    if (location.startsWith(AppRoutes.guardianSummary)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex(context),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: tr(
            context,
            fr: 'Tableau',
            en: 'Dashboard',
            ar: 'لوحة المتابعة',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications_active),
          label: tr(
            context,
            fr: 'Alertes',
            en: 'Alerts',
            ar: 'التنبيهات',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.timeline_outlined),
          selectedIcon: const Icon(Icons.timeline),
          label: tr(
            context,
            fr: 'Chronologie',
            en: 'Timeline',
            ar: 'التسلسل',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.auto_awesome_outlined),
          selectedIcon: const Icon(Icons.auto_awesome),
          label: tr(
            context,
            fr: 'Résumé',
            en: 'Summary',
            ar: 'الملخص',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: tr(
            context,
            fr: 'Paramètres',
            en: 'Settings',
            ar: 'الإعدادات',
          ),
        ),
      ],
      onDestinationSelected: (index) {
        final target = _routes[index];
        if (GoRouterState.of(context).uri.toString() == target) {
          return;
        }
        context.go(target);
      },
    );
  }
}
