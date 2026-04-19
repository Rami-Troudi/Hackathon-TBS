import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/theme/app_theme.dart';
import 'package:senior_companion/shared/constants/app_constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SeniorCompanionApp extends ConsumerStatefulWidget {
  const SeniorCompanionApp({super.key});

  @override
  ConsumerState<SeniorCompanionApp> createState() => _SeniorCompanionAppState();
}

class _SeniorCompanionAppState extends ConsumerState<SeniorCompanionApp> {
  @override
  void initState() {
    super.initState();
    try {
      ref.read(fallDetectionServiceProvider).start();
    } on UnimplementedError {
      // Allow widget-only tests that mount the app without bootstrap overrides.
    }
    WakelockPlus.enable();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(appPresentationSettingsProvider).valueOrNull;
    final locale = presentation?.locale ?? const Locale('fr');
    final textScale = presentation?.textScale ?? 1.0;
    final highContrast = presentation?.highContrast ?? false;

    final baseTheme = AppTheme.light;
    final theme = highContrast
        ? baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              surface: Colors.white,
              onSurface: Colors.black,
              primary: Colors.black,
              onPrimary: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
          )
        : baseTheme;

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: theme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
