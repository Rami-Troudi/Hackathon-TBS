import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/app/theme/app_colors.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';

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
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications_active),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.timeline_outlined),
          selectedIcon: Icon(Icons.timeline),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Summary',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
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
