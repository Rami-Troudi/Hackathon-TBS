class GuardianProfile {
  const GuardianProfile({
    required this.id,
    required this.displayName,
    required this.relationshipLabel,
    required this.pushAlertNotificationsEnabled,
    required this.dailySummaryEnabled,
    required this.linkedSeniorIds,
  });

  final String id;
  final String displayName;
  final String relationshipLabel;
  final bool pushAlertNotificationsEnabled;
  final bool dailySummaryEnabled;
  final List<String> linkedSeniorIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'relationshipLabel': relationshipLabel,
        'pushAlertNotificationsEnabled': pushAlertNotificationsEnabled,
        'dailySummaryEnabled': dailySummaryEnabled,
        'linkedSeniorIds': linkedSeniorIds,
      };

  factory GuardianProfile.fromJson(Map<String, dynamic> json) =>
      GuardianProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        relationshipLabel: json['relationshipLabel'] as String,
        pushAlertNotificationsEnabled:
            json['pushAlertNotificationsEnabled'] as bool? ?? true,
        dailySummaryEnabled: json['dailySummaryEnabled'] as bool? ?? true,
        linkedSeniorIds:
            (json['linkedSeniorIds'] as List<dynamic>? ?? const <dynamic>[])
                .map((item) => item as String)
                .toList(),
      );
}
