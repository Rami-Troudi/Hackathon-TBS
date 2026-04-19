import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/app/router/app_routes.dart';

void main() {
  test('all production route paths are unique', () {
    final paths = <String>[
      AppRoutes.splash,
      AppRoutes.onboardingRole,
      AppRoutes.onboardingProfile,
      AppRoutes.home,
      AppRoutes.seniorHome,
      AppRoutes.checkIn,
      AppRoutes.medication,
      AppRoutes.incident,
      AppRoutes.seniorHydration,
      AppRoutes.seniorNutrition,
      AppRoutes.seniorSummary,
      AppRoutes.seniorCompanion,
      AppRoutes.guardianHome,
      AppRoutes.guardianAlerts,
      AppRoutes.guardianTimeline,
      AppRoutes.guardianCheckIns,
      AppRoutes.guardianMedication,
      AppRoutes.guardianIncidents,
      AppRoutes.guardianProfile,
      AppRoutes.guardianHydration,
      AppRoutes.guardianNutrition,
      AppRoutes.guardianLocation,
      AppRoutes.guardianSummary,
      AppRoutes.guardianInsights,
      AppRoutes.settings,
    ];

    expect(paths.toSet().length, paths.length);
  });

  test('app_router registers all production route constants', () {
    final source = File('lib/app/router/app_router.dart').readAsStringSync();

    final requiredRouteRefs = <String>[
      'path: AppRoutes.splash',
      'path: AppRoutes.onboardingRole',
      "path: '\${AppRoutes.onboardingProfile}/:role'",
      'path: AppRoutes.home',
      'path: AppRoutes.seniorHome',
      'path: AppRoutes.checkIn',
      'path: AppRoutes.medication',
      'path: AppRoutes.incident',
      'path: AppRoutes.seniorHydration',
      'path: AppRoutes.seniorNutrition',
      'path: AppRoutes.seniorSummary',
      'path: AppRoutes.seniorCompanion',
      'path: AppRoutes.guardianHome',
      'path: AppRoutes.guardianAlerts',
      'path: AppRoutes.guardianTimeline',
      'path: AppRoutes.guardianCheckIns',
      'path: AppRoutes.guardianMedication',
      'path: AppRoutes.guardianIncidents',
      'path: AppRoutes.guardianProfile',
      'path: AppRoutes.guardianHydration',
      'path: AppRoutes.guardianNutrition',
      'path: AppRoutes.guardianLocation',
      'path: AppRoutes.guardianSummary',
      'path: AppRoutes.guardianInsights',
      'path: AppRoutes.settings',
    ];

    for (final reference in requiredRouteRefs) {
      expect(source, contains(reference));
    }
  });
}
