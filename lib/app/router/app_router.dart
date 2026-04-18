import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/features/check_in/check_in_screen.dart';
import 'package:senior_companion/features/onboarding/profile_selection_screen.dart';
import 'package:senior_companion/features/onboarding/role_selection_screen.dart';
import 'package:senior_companion/features/guardian/guardian_home_placeholder_screen.dart';
import 'package:senior_companion/features/home/home_screen.dart';
import 'package:senior_companion/features/incident/incident_confirmation_screen.dart';
import 'package:senior_companion/features/medication/medication_screen.dart';
import 'package:senior_companion/features/senior/senior_home_screen.dart';
import 'package:senior_companion/features/settings/settings_screen.dart';
import 'package:senior_companion/features/splash/splash_screen.dart';
import 'package:senior_companion/shared/models/app_role.dart';

GoRouter buildAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingRole,
        name: 'onboarding-role',
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.onboardingProfile}/:role',
        name: 'onboarding-profile',
        builder: (_, state) {
          final role =
              AppRoleX.fromRaw(state.pathParameters['role'] ?? 'senior');
          return ProfileSelectionScreen(role: role);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.seniorHome,
        name: 'senior-home',
        builder: (_, __) => const SeniorHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkIn,
        name: 'check-in',
        builder: (_, __) => const CheckInScreen(),
      ),
      GoRoute(
        path: AppRoutes.medication,
        name: 'medication',
        builder: (_, __) => const MedicationScreen(),
      ),
      GoRoute(
        path: AppRoutes.incident,
        name: 'incident',
        builder: (_, __) => const IncidentConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianHome,
        name: 'guardian-home',
        builder: (_, __) => const GuardianHomePlaceholderScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
