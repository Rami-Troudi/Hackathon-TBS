import 'package:senior_companion/shared/models/app_role.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboardingRole = '/onboarding/role';
  static const onboardingProfile = '/onboarding/profile';
  static const home = '/home';
  static const seniorHome = '/senior';
  static const guardianHome = '/guardian';
  static const settings = '/settings';

  static String onboardingProfileForRole(AppRole role) {
    return '$onboardingProfile/${role.value}';
  }
}
