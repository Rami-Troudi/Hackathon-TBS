import 'package:senior_companion/shared/models/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> fetchDashboardSummary();
}
