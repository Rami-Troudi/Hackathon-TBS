import 'package:senior_companion/shared/models/app_role.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboardingRole = '/onboarding/role';
  static const onboardingProfile = '/onboarding/profile';
  static const home = '/home';
  static const seniorHome = '/senior';
  static const checkIn = '/senior/check-in';
  static const medication = '/senior/medication';
  static const incident = '/senior/incident';
  static const seniorHydration = '/senior/hydration';
  static const seniorNutrition = '/senior/nutrition';
  static const seniorSummary = '/senior/summary';
  static const guardianHome = '/guardian';
  static const guardianAlerts = '/guardian/alerts';
  static const guardianTimeline = '/guardian/timeline';
  static const guardianCheckIns = '/guardian/check-ins';
  static const guardianMedication = '/guardian/medication';
  static const guardianIncidents = '/guardian/incidents';
  static const guardianProfile = '/guardian/profile';
  static const guardianHydration = '/guardian/hydration';
  static const guardianNutrition = '/guardian/nutrition';
  static const guardianLocation = '/guardian/location';
  static const guardianSummary = '/guardian/summary';
  static const settings = '/settings';

  static String onboardingProfileForRole(AppRole role) {
    return '$onboardingProfile/${role.value}';
  }
}
