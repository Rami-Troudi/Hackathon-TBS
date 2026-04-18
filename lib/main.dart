import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/app.dart';
import 'package:senior_companion/app/bootstrap/app_bootstrap.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appEnvironment = AppEnvironmentX.fromRaw(
    const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
  );
  final bootstrapData = await AppBootstrap.bootstrap(environment: appEnvironment);
  final logger = bootstrapData.logger;

  FlutterError.onError = (details) {
    logger.error('Flutter framework error', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Platform error', error, stack);
    return true;
  };

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: bootstrapData.overrides,
          child: const SeniorCompanionApp(),
        ),
      );
    },
    (error, stack) => logger.error('Uncaught zone error', error, stack),
  );
}
