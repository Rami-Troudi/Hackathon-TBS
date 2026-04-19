import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/incident_repository.dart';

class FallDetectionService {
  FallDetectionService({
    required this.logger,
    required this.activeSeniorResolver,
    required this.incidentRepository,
  });

  final AppLogger logger;
  final ActiveSeniorResolver activeSeniorResolver;
  final IncidentRepository incidentRepository;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastTriggerAt;
  DateTime? _lastFreeFallAt;

  bool get isRunning => _subscription != null;

  void start() {
    if (_subscription != null) return;
    _subscription = accelerometerEventStream().listen(_onAcceleration);
    logger.info('FallDetectionService started');
  }

  Future<void> _onAcceleration(AccelerometerEvent event) async {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();

    // Require a fall-like sequence instead of a single spike:
    // 1) free-fall / near-weightless movement
    // 2) impact shortly after.
    const freeFallThreshold = 4.0;
    const impactThreshold = 28.0;
    const impactWindow = Duration(milliseconds: 1400);

    if (magnitude <= freeFallThreshold) {
      _lastFreeFallAt = now;
      return;
    }

    final freeFallAt = _lastFreeFallAt;
    if (freeFallAt == null || now.difference(freeFallAt) > impactWindow) {
      return;
    }
    if (magnitude < impactThreshold) return;

    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastTriggerAt = now;
    _lastFreeFallAt = null;

    final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
    if (seniorId == null) return;

    logger.warn(
      'Fall-like sequence detected for $seniorId (impactMagnitude=$magnitude)',
    );
    await incidentRepository.reportSuspiciousIncident(
      seniorId,
      now: now,
      confidenceScore: 0.92,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
