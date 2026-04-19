import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/fall_detection/fall_detection_service.dart';
import 'package:senior_companion/core/fall_detection/motion_sample.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/active_senior_resolver.dart';
import 'package:senior_companion/core/repositories/incident_repository.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';

void main() {
  group('SensorFallDetectionService', () {
    late StreamController<MotionSample> controller;
    late FakeIncidentRepository incidentRepository;
    late FakeActiveSeniorResolver activeSeniorResolver;
    late FakeLogger logger;

    setUp(() {
      controller = StreamController<MotionSample>.broadcast();
      incidentRepository = FakeIncidentRepository();
      activeSeniorResolver = FakeActiveSeniorResolver('senior-1');
      logger = FakeLogger();
    });

    tearDown(() async {
      await controller.close();
    });

    test('reports a suspicious incident after free fall followed by impact',
        () async {
      final service = SensorFallDetectionService(
        activeSeniorResolver: activeSeniorResolver,
        incidentRepository: incidentRepository,
        logger: logger,
        sensorStreamFactory: () => controller.stream,
        config: const FallDetectionConfig(
          freeFallThreshold: 2.5,
          impactThreshold: 22.0,
          freeFallWindow: Duration(milliseconds: 1200),
          cooldown: Duration(seconds: 10),
        ),
      );

      await service.initialize();

      final start = DateTime.utc(2026, 4, 19, 12, 0, 0);
      controller.add(
        MotionSample(x: 0.3, y: 0.5, z: 1.2, capturedAt: start),
      );
      controller.add(
        MotionSample(
          x: 0.0,
          y: 0.0,
          z: 25.0,
          capturedAt: start.add(const Duration(milliseconds: 700)),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(incidentRepository.calls, hasLength(1));
      expect(incidentRepository.calls.single.seniorId, 'senior-1');
      expect(incidentRepository.calls.single.confidenceScore, greaterThan(0));

      await service.dispose();
    });

    test('does not report if impact never follows free fall', () async {
      final service = SensorFallDetectionService(
        activeSeniorResolver: activeSeniorResolver,
        incidentRepository: incidentRepository,
        logger: logger,
        sensorStreamFactory: () => controller.stream,
      );

      await service.initialize();

      final start = DateTime.utc(2026, 4, 19, 12, 0, 0);
      controller.add(
        MotionSample(x: 0.4, y: 0.5, z: 1.0, capturedAt: start),
      );
      controller.add(
        MotionSample(
          x: 1.2,
          y: 1.0,
          z: 1.1,
          capturedAt: start.add(const Duration(seconds: 2)),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(incidentRepository.calls, isEmpty);

      await service.dispose();
    });

    test('simulateFall sends a suspicious incident immediately', () async {
      final service = SensorFallDetectionService(
        activeSeniorResolver: activeSeniorResolver,
        incidentRepository: incidentRepository,
        logger: logger,
        sensorStreamFactory: () => controller.stream,
      );

      await service.simulateFall(
        now: DateTime.utc(2026, 4, 19, 12, 0, 0),
        confidenceScore: 0.91,
      );

      expect(incidentRepository.calls, hasLength(1));
      expect(incidentRepository.calls.single.confidenceScore, 0.91);
    });
  });
}

class FakeIncidentRepository implements IncidentRepository {
  final List<RecordedIncident> calls = <RecordedIncident>[];

  @override
  Future<IncidentFlowState> getCurrentState(String seniorId) async {
    return const IncidentFlowState(
      status: IncidentFlowStatus.clear,
      openSuspectedIncidents: 0,
      openConfirmedIncidents: 0,
    );
  }

  @override
  Future<void> confirmIncident(String seniorId, {DateTime? now}) async {}

  @override
  Future<void> dismissIncident(String seniorId, {DateTime? now}) async {}

  @override
  Future<void> reportSuspiciousIncident(
    String seniorId, {
    DateTime? now,
    double confidenceScore = 0.75,
  }) async {
    calls.add(
      RecordedIncident(
        seniorId: seniorId,
        confidenceScore: confidenceScore,
        now: now ?? DateTime.now(),
      ),
    );
  }

  @override
  Future<void> requestImmediateHelp(String seniorId, {DateTime? now}) async {}

  @override
  Future<void> triggerEmergency(String seniorId, {DateTime? now}) async {}
}

class RecordedIncident {
  const RecordedIncident({
    required this.seniorId,
    required this.confidenceScore,
    required this.now,
  });

  final String seniorId;
  final double confidenceScore;
  final DateTime now;
}

class FakeActiveSeniorResolver implements ActiveSeniorResolver {
  FakeActiveSeniorResolver(this.seniorId);

  final String? seniorId;

  @override
  Future<String?> resolveActiveSeniorId() async => seniorId;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class FakeLogger implements AppLogger {
  final List<String> messages = <String>[];

  @override
  void debug(String message) {
    messages.add('debug:$message');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    messages.add('error:$message');
  }

  @override
  void info(String message) {
    messages.add('info:$message');
  }

  @override
  void warn(String message) {
    messages.add('warn:$message');
  }
}