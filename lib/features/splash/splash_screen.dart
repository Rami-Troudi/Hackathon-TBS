import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/app_role.dart';

/// Minimum time the splash screen is visible.
///
/// In debug mode this is kept very short to avoid slowing down the dev loop.
/// In release mode it provides just enough time to feel intentional without
/// making the user wait.
const _kSplashMinDuration =
    kDebugMode ? Duration(milliseconds: 100) : Duration(milliseconds: 800);

/// The entry point screen shown immediately on app launch.
///
/// Responsibilities:
/// 1. Display the app brand while initialization completes.
/// 2. Read the saved session from local storage.
/// 3. Route the user to the correct experience:
///    - No session → [AppRoutes.onboardingRole]
///    - Session with senior role → [AppRoutes.seniorHome]
///    - Session with guardian role → [AppRoutes.guardianHome]
///
/// The minimum display duration is respected regardless of how fast the
/// async work completes, so the splash never flickers on fast devices.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Start timing immediately so the minimum duration accounts for
    // the async work itself, not just an artificial delay after it.
    final stopwatch = Stopwatch()..start();

    final sessionRepo = ref.read(appSessionRepositoryProvider);
    final session = await sessionRepo.getSession();
    String destination;

    // Enforce minimum splash visibility.
    final elapsed = stopwatch.elapsed;
    final remaining = _kSplashMinDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (session == null) {
      destination = AppRoutes.onboardingRole;
    } else {
      final profileRepository = ref.read(profileRepositoryProvider);
      final hasProfile = switch (session.activeRole) {
        AppRole.senior => await profileRepository
                .getSeniorProfileById(session.activeProfileId) !=
            null,
        AppRole.guardian => await profileRepository
                .getGuardianProfileById(session.activeProfileId) !=
            null,
      };
      if (!hasProfile) {
        await sessionRepo.clearSession();
        destination = AppRoutes.onboardingRole;
      } else {
        destination = switch (session.activeRole) {
          AppRole.senior => AppRoutes.seniorHome,
          AppRole.guardian => AppRoutes.guardianHome,
        };
      }
    }

    if (!mounted) return;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            Gaps.v16,
            Text(
              'Senior Companion',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Gaps.v8,
            Text(
              'Loading your profile...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.v24,
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
