class MedicationPlan {
  const MedicationPlan({
    required this.id,
    required this.seniorId,
    required this.medicationName,
    required this.dosageLabel,
    required this.scheduledTimes,
    required this.isActive,
    this.note,
  });

  final String id;
  final String seniorId;
  final String medicationName;
  final String dosageLabel;
  final List<String> scheduledTimes;
  final bool isActive;
  final String? note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'seniorId': seniorId,
        'medicationName': medicationName,
        'dosageLabel': dosageLabel,
        'scheduledTimes': scheduledTimes,
        'isActive': isActive,
        'note': note,
      };

  factory MedicationPlan.fromJson(Map<String, dynamic> json) => MedicationPlan(
        id: json['id'] as String,
        seniorId: json['seniorId'] as String,
        medicationName: json['medicationName'] as String,
        dosageLabel: json['dosageLabel'] as String,
        scheduledTimes: (json['scheduledTimes'] as List<dynamic>)
            .map((item) => item as String)
            .toList(),
        isActive: json['isActive'] as bool? ?? true,
        note: json['note'] as String?,
      );
}
