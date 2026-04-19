enum DailySummaryAudience {
  senior,
  guardian,
}

class DailySummary {
  const DailySummary({
    required this.audience,
    required this.headline,
    required this.whatWentWell,
    required this.needsAttention,
    required this.notableEvents,
    required this.generatedAt,
  });

  final DailySummaryAudience audience;
  final String headline;
  final List<String> whatWentWell;
  final List<String> needsAttention;
  final List<String> notableEvents;
  final DateTime generatedAt;
}
