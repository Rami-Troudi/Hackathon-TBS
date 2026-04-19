class SeniorProfile {
  const SeniorProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.preferredLanguage,
    required this.largeTextEnabled,
    required this.highContrastEnabled,
    required this.linkedGuardianIds,
  });

  final String id;
  final String displayName;
  final int age;
  final String preferredLanguage;
  final bool largeTextEnabled;
  final bool highContrastEnabled;
  final List<String> linkedGuardianIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'age': age,
        'preferredLanguage': preferredLanguage,
        'largeTextEnabled': largeTextEnabled,
        'highContrastEnabled': highContrastEnabled,
        'linkedGuardianIds': linkedGuardianIds,
      };

  factory SeniorProfile.fromJson(Map<String, dynamic> json) => SeniorProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        age: json['age'] as int,
        preferredLanguage: json['preferredLanguage'] as String,
        largeTextEnabled: json['largeTextEnabled'] as bool? ?? false,
        highContrastEnabled: json['highContrastEnabled'] as bool? ?? false,
        linkedGuardianIds:
            (json['linkedGuardianIds'] as List<dynamic>? ?? const <dynamic>[])
                .map((item) => item as String)
                .toList(),
      );
}
