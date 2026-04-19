import 'dart:async';

import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/incident_repository.dart';

import 'motion_sample.dart';

typedef MotionSampleStreamFactory = Stream<MotionSample> Function();

class FallDetectionConfig {
  const FallDetectionConfig({
    this.freeFallThreshold = 2.5,
    this.impactThreshold = 22.0,
    this.freeFallWindow = const Duration(milliseconds: 1200),
    this.cooldown = const Duration(seconds: 45),
  });

  final double freeFallThreshold;
  final double impactThreshold;
  final Duration freeFallWindow;
  final Duration cooldown;
}

abstract class FallDetectionService {
  Future<void> initialize();

  Future<void> dispose();

  Future<void> simulateFall({
    DateTime? now,
    double confidenceScore,
  });
}

class SensorFallDetectionService implements FallDetectionService {
  SensorFallDetectionService({
    required this.activeSeniorResolver,
    required this.incidentRepository,
    required this.logger,
    required this.sensorStreamFactory,
    this.config = const FallDetectionConfig(),
  });

  final ActiveSeniorResolver activeSeniorResolver;
  final IncidentRepository incidentRepository;
  final AppLogger logger;
  final MotionSampleStreamFactory sensorStreamFactory;
  final FallDetectionConfig config;

  StreamSubscription<MotionSample>? _subscription;
  DateTime? _freeFallStartedAt;
  DateTime? _lastDetectionAt;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _subscription = sensorStreamFactory().listen(
        _handleSample,
        onError: (Object error, StackTrace stackTrace) {
          logger.warn(
            'FallDetectionService: sensor stream error $error\n$stackTrace',
          );
        },
      );
      logger.info('FallDetectionService: listening for phone motion events');
    } catch (error, stackTrace) {
      logger.error(
        'FallDetectionService: failed to start sensor monitoring',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _freeFallStartedAt = null;
    _lastDetectionAt = null;
    _initialized = false;
  }

  @override
  Future<void> simulateFall({
    DateTime? now,
    double confidenceScore = 0.95,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    await _reportFall(
      timestamp,
      confidenceScore: confidenceScore,
      source: 'sensor.fall_detection.simulated',
    );
    _lastDetectionAt = timestamp;
  }

  Future<void> _handleSample(MotionSample sample) async {
    final now = sample.capturedAt.toUtc();
    if (_lastDetectionAt != null &&
        now.difference(_lastDetectionAt!) < config.cooldown) {
      return;
    }

    final magnitude = sample.magnitude;
    if (_freeFallStartedAt == null) {
      if (magnitude <= config.freeFallThreshold) {
        _freeFallStartedAt = now;
        logger.debug(
          'FallDetectionService: possible free fall detected magnitude='
          '${magnitude.toStringAsFixed(2)}',
        );
      }
      return;
    }

    final elapsed = now.difference(_freeFallStartedAt!);
    if (elapsed > config.freeFallWindow) {
      _freeFallStartedAt = null;
      return;
    }

    if (magnitude < config.impactThreshold) {
      return;
    }

    final confidenceScore = _confidenceFor(
      impactMagnitude: magnitude,
      elapsedSinceFreeFall: elapsed,
    );
    _freeFallStartedAt = null;
    _lastDetectionAt = now;
    await _reportFall(
      now,
      confidenceScore: confidenceScore,
      source: 'sensor.fall_detection',
    );
  }

  double _confidenceFor({
    required double impactMagnitude,
    required Duration elapsedSinceFreeFall,
  }) {
    final impactScore = ((impactMagnitude - config.impactThreshold) / 12.0)
        .clamp(0.0, 1.0);
    final timingScore = (1.0 -
            elapsedSinceFreeFall.inMilliseconds /
                config.freeFallWindow.inMilliseconds)
        .clamp(0.0, 1.0);
    return (0.62 + (impactScore * 0.25) + (timingScore * 0.13))
        .clamp(0.0, 1.0);
  }

  Future<void> _reportFall(
    DateTime now, {
    required double confidenceScore,
    required String source,
  }) async {
    final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
    if (seniorId == null) {
      logger.warn(
        'FallDetectionService: fall detected but no active senior profile is '
        'available',
      );
      return;
    }

    logger.warn(
      'FallDetectionService: suspected fall for seniorId=$seniorId '
      'confidence=${confidenceScore.toStringAsFixed(2)} source=$source',
    );

    await incidentRepository.reportSuspiciousIncident(
      seniorId,
      now: now,
      confidenceScore: confidenceScore,
    );
  }
}