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

  bool get isRunning => _subscription != null;

  void start() {
    if (_subscription != null) return;
    _subscription = accelerometerEvents.listen(_onAcceleration);
    logger.info('FallDetectionService started');
  }

  Future<void> _onAcceleration(AccelerometerEvent event) async {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    const triggerThreshold = 25.0;
    if (magnitude < triggerThreshold) return;

    final now = DateTime.now();
    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastTriggerAt = now;

    final seniorId = await activeSeniorResolver.resolveActiveSeniorId();
    if (seniorId == null) return;

    logger.warn(
      'Fall-like acceleration detected for $seniorId (magnitude=$magnitude)',
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
