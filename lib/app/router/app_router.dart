import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/features/check_in/check_in_screen.dart';
import 'package:senior_companion/features/companion/guardian_insights_screen.dart';
import 'package:senior_companion/features/companion/senior_companion_screen.dart';
import 'package:senior_companion/features/onboarding/profile_selection_screen.dart';
import 'package:senior_companion/features/onboarding/role_selection_screen.dart';
import 'package:senior_companion/features/guardian/guardian_alerts_screen.dart';
import 'package:senior_companion/features/guardian/guardian_check_in_screen.dart';
import 'package:senior_companion/features/guardian/guardian_home_screen.dart';
import 'package:senior_companion/features/guardian/guardian_incident_screen.dart';
import 'package:senior_companion/features/guardian/guardian_medication_screen.dart';
import 'package:senior_companion/features/guardian/guardian_profile_screen.dart';
import 'package:senior_companion/features/guardian/guardian_timeline_screen.dart';
import 'package:senior_companion/features/hydration/guardian_hydration_screen.dart';
import 'package:senior_companion/features/hydration/hydration_screen.dart';
import 'package:senior_companion/features/home/home_screen.dart';
import 'package:senior_companion/features/incident/incident_confirmation_screen.dart';
import 'package:senior_companion/features/location/guardian_location_screen.dart';
import 'package:senior_companion/features/medication/medication_screen.dart';
import 'package:senior_companion/features/nutrition/guardian_nutrition_screen.dart';
import 'package:senior_companion/features/nutrition/nutrition_screen.dart';
import 'package:senior_companion/features/senior/senior_home_screen.dart';
import 'package:senior_companion/features/settings/settings_screen.dart';
import 'package:senior_companion/features/splash/splash_screen.dart';
import 'package:senior_companion/features/summary/guardian_summary_screen.dart';
import 'package:senior_companion/features/summary/senior_summary_screen.dart';
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
        path: AppRoutes.seniorHydration,
        name: 'senior-hydration',
        builder: (_, __) => const HydrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.seniorNutrition,
        name: 'senior-nutrition',
        builder: (_, __) => const NutritionScreen(),
      ),
      GoRoute(
        path: AppRoutes.seniorSummary,
        name: 'senior-summary',
        builder: (_, __) => const SeniorSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.seniorCompanion,
        name: 'senior-companion',
        builder: (_, __) => const SeniorCompanionScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianHome,
        name: 'guardian-home',
        builder: (_, __) => const GuardianHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianAlerts,
        name: 'guardian-alerts',
        builder: (_, __) => const GuardianAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianTimeline,
        name: 'guardian-timeline',
        builder: (_, __) => const GuardianTimelineScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianCheckIns,
        name: 'guardian-check-ins',
        builder: (_, __) => const GuardianCheckInScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianMedication,
        name: 'guardian-medication',
        builder: (_, __) => const GuardianMedicationScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianIncidents,
        name: 'guardian-incidents',
        builder: (_, __) => const GuardianIncidentScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianProfile,
        name: 'guardian-profile',
        builder: (_, __) => const GuardianProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianHydration,
        name: 'guardian-hydration',
        builder: (_, __) => const GuardianHydrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianNutrition,
        name: 'guardian-nutrition',
        builder: (_, __) => const GuardianNutritionScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianLocation,
        name: 'guardian-location',
        builder: (_, __) => const GuardianLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianSummary,
        name: 'guardian-summary',
        builder: (_, __) => const GuardianSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardianInsights,
        name: 'guardian-insights',
        builder: (_, __) => const GuardianInsightsScreen(),
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
