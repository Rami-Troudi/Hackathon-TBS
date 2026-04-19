import 'package:senior_companion/shared/models/daily_summary.dart';

abstract class SummaryRepository {
  Future<DailySummary> buildSeniorDailySummary(
    String seniorId, {
    DateTime? now,
  });

  Future<DailySummary> buildGuardianDailySummary(
    String seniorId, {
    DateTime? now,
  });
}
