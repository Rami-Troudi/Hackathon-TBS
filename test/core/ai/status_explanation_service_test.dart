import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/ai/status_explanation_service.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

void main() {
  test('status explanation highlights missed routines and location state', () {
    const service = StatusExplanationService();
    const summary = DashboardSummary(
      globalStatus: SeniorGlobalStatus.watch,
      pendingAlerts: 2,
      todayCheckIns: 0,
      missedMedications: 1,
      openIncidents: 0,
    );

    final reasons = service.buildStatusReasons(
      summary: summary,
      hydrationMissedToday: 2,
      mealsMissedToday: 1,
      isOutsideSafeZone: true,
    );

    expect(reasons.any((line) => line.contains('check-in')), isTrue);
    expect(reasons.any((line) => line.contains('Medication')), isTrue);
    expect(reasons.any((line) => line.contains('Hydration')), isTrue);
    expect(reasons.any((line) => line.contains('Meal')), isTrue);
    expect(reasons.any((line) => line.contains('outside safe zones')), isTrue);
  });
}
