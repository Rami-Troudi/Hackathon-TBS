import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

class StatusExplanationService {
  const StatusExplanationService();

  List<String> buildStatusReasons({
    required DashboardSummary summary,
    required int hydrationMissedToday,
    required int mealsMissedToday,
    required bool isOutsideSafeZone,
  }) {
    final reasons = <String>[
      if (summary.todayCheckIns == 0)
        'No completed check-in was recorded today.',
      if (summary.missedMedications > 0)
        'Medication misses were recorded today.',
      if (summary.openIncidents > 0) 'There are unresolved incident signals.',
      if (hydrationMissedToday > 0) 'Hydration reminders were missed today.',
      if (mealsMissedToday > 0) 'Meal reminders were missed today.',
      if (isOutsideSafeZone) 'The senior is currently outside safe zones.',
    ];

    if (reasons.isEmpty) {
      return const <String>[
        'No warning signals are currently active in the local monitoring data.',
      ];
    }
    return reasons;
  }

  String explainForSenior({
    required SeniorGlobalStatus status,
    required DashboardSummary summary,
    required int hydrationMissedToday,
    required int mealsMissedToday,
    required bool isOutsideSafeZone,
  }) {
    final reasons = buildStatusReasons(
      summary: summary,
      hydrationMissedToday: hydrationMissedToday,
      mealsMissedToday: mealsMissedToday,
      isOutsideSafeZone: isOutsideSafeZone,
    );

    return switch (status) {
      SeniorGlobalStatus.ok =>
        'You are currently in a good status. Keep following your routine.',
      SeniorGlobalStatus.watch =>
        'Your status is watch because: ${reasons.take(2).join(' ')}',
      SeniorGlobalStatus.actionRequired =>
        'Your status is action required because: ${reasons.take(3).join(' ')}',
    };
  }

  String explainForGuardian({
    required SeniorGlobalStatus status,
    required DashboardSummary summary,
    required int hydrationMissedToday,
    required int mealsMissedToday,
    required bool isOutsideSafeZone,
  }) {
    final reasons = buildStatusReasons(
      summary: summary,
      hydrationMissedToday: hydrationMissedToday,
      mealsMissedToday: mealsMissedToday,
      isOutsideSafeZone: isOutsideSafeZone,
    );
    final prefix = switch (status) {
      SeniorGlobalStatus.ok => 'Status is OK',
      SeniorGlobalStatus.watch => 'Status is WATCH',
      SeniorGlobalStatus.actionRequired => 'Status is ACTION REQUIRED',
    };
    return '$prefix. Main drivers: ${reasons.take(4).join(' ')}';
  }
}
