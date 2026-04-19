enum ReminderIntensity {
  low,
  normal,
  high,
}

enum AlertSensitivity {
  low,
  normal,
  high,
}

class SeniorSettingsPreferences {
  const SeniorSettingsPreferences({
    required this.largeTextEnabled,
    required this.highContrastEnabled,
    required this.notificationsEnabled,
    required this.reminderIntensity,
    required this.languageCode,
    required this.emergencyContactLabel,
    required this.simplifiedModeEnabled,
    required this.checkInModuleEnabled,
    required this.medicationModuleEnabled,
    required this.companionModuleEnabled,
    required this.incidentModuleEnabled,
  });

  final bool largeTextEnabled;
  final bool highContrastEnabled;
  final bool notificationsEnabled;
  final ReminderIntensity reminderIntensity;
  final String languageCode;
  final String emergencyContactLabel;
  final bool simplifiedModeEnabled;
  final bool checkInModuleEnabled;
  final bool medicationModuleEnabled;
  final bool companionModuleEnabled;
  final bool incidentModuleEnabled;

  factory SeniorSettingsPreferences.defaults() =>
      const SeniorSettingsPreferences(
        largeTextEnabled: true,
        highContrastEnabled: false,
        notificationsEnabled: true,
        reminderIntensity: ReminderIntensity.normal,
        languageCode: 'fr',
        emergencyContactLabel: 'Family contact',
        simplifiedModeEnabled: false,
        checkInModuleEnabled: true,
        medicationModuleEnabled: true,
        companionModuleEnabled: true,
        incidentModuleEnabled: true,
      );

  SeniorSettingsPreferences copyWith({
    bool? largeTextEnabled,
    bool? highContrastEnabled,
    bool? notificationsEnabled,
    ReminderIntensity? reminderIntensity,
    String? languageCode,
    String? emergencyContactLabel,
    bool? simplifiedModeEnabled,
    bool? checkInModuleEnabled,
    bool? medicationModuleEnabled,
    bool? companionModuleEnabled,
    bool? incidentModuleEnabled,
  }) {
    return SeniorSettingsPreferences(
      largeTextEnabled: largeTextEnabled ?? this.largeTextEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderIntensity: reminderIntensity ?? this.reminderIntensity,
      languageCode: languageCode ?? this.languageCode,
      emergencyContactLabel:
          emergencyContactLabel ?? this.emergencyContactLabel,
      simplifiedModeEnabled:
          simplifiedModeEnabled ?? this.simplifiedModeEnabled,
      checkInModuleEnabled: checkInModuleEnabled ?? this.checkInModuleEnabled,
      medicationModuleEnabled:
          medicationModuleEnabled ?? this.medicationModuleEnabled,
      companionModuleEnabled:
          companionModuleEnabled ?? this.companionModuleEnabled,
      incidentModuleEnabled:
          incidentModuleEnabled ?? this.incidentModuleEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'largeTextEnabled': largeTextEnabled,
        'highContrastEnabled': highContrastEnabled,
        'notificationsEnabled': notificationsEnabled,
        'reminderIntensity': reminderIntensity.name,
        'languageCode': languageCode,
        'emergencyContactLabel': emergencyContactLabel,
        'simplifiedModeEnabled': simplifiedModeEnabled,
        'checkInModuleEnabled': checkInModuleEnabled,
        'medicationModuleEnabled': medicationModuleEnabled,
        'companionModuleEnabled': companionModuleEnabled,
        'incidentModuleEnabled': incidentModuleEnabled,
      };

  factory SeniorSettingsPreferences.fromJson(Map<String, dynamic> json) {
    final defaults = SeniorSettingsPreferences.defaults();
    return SeniorSettingsPreferences(
      largeTextEnabled:
          json['largeTextEnabled'] as bool? ?? defaults.largeTextEnabled,
      highContrastEnabled:
          json['highContrastEnabled'] as bool? ?? defaults.highContrastEnabled,
      notificationsEnabled: json['notificationsEnabled'] as bool? ??
          defaults.notificationsEnabled,
      reminderIntensity: _reminderIntensityFromRaw(
        json['reminderIntensity'] as String?,
        fallback: defaults.reminderIntensity,
      ),
      languageCode: json['languageCode'] as String? ?? defaults.languageCode,
      emergencyContactLabel: json['emergencyContactLabel'] as String? ??
          defaults.emergencyContactLabel,
      simplifiedModeEnabled: json['simplifiedModeEnabled'] as bool? ??
          defaults.simplifiedModeEnabled,
      checkInModuleEnabled: json['checkInModuleEnabled'] as bool? ??
          defaults.checkInModuleEnabled,
      medicationModuleEnabled: json['medicationModuleEnabled'] as bool? ??
          defaults.medicationModuleEnabled,
      companionModuleEnabled: json['companionModuleEnabled'] as bool? ??
          defaults.companionModuleEnabled,
      incidentModuleEnabled: json['incidentModuleEnabled'] as bool? ??
          defaults.incidentModuleEnabled,
    );
  }
}

class GuardianSettingsPreferences {
  const GuardianSettingsPreferences({
    required this.notificationsEnabled,
    required this.alertSensitivity,
    required this.dailyDigestEnabled,
    required this.weeklyDigestEnabled,
    required this.showMedicationReminders,
    required this.showHydrationReminders,
    required this.showNutritionReminders,
    required this.showLocationUpdates,
    required this.linkedSeniorInfoVisible,
    required this.showCheckInMonitoring,
    required this.showIncidentMonitoring,
    required this.showInsightsModule,
  });

  final bool notificationsEnabled;
  final AlertSensitivity alertSensitivity;
  final bool dailyDigestEnabled;
  final bool weeklyDigestEnabled;
  final bool showMedicationReminders;
  final bool showHydrationReminders;
  final bool showNutritionReminders;
  final bool showLocationUpdates;
  final bool linkedSeniorInfoVisible;
  final bool showCheckInMonitoring;
  final bool showIncidentMonitoring;
  final bool showInsightsModule;

  factory GuardianSettingsPreferences.defaults() =>
      const GuardianSettingsPreferences(
        notificationsEnabled: true,
        alertSensitivity: AlertSensitivity.normal,
        dailyDigestEnabled: true,
        weeklyDigestEnabled: false,
        showMedicationReminders: true,
        showHydrationReminders: true,
        showNutritionReminders: true,
        showLocationUpdates: true,
        linkedSeniorInfoVisible: true,
        showCheckInMonitoring: true,
        showIncidentMonitoring: true,
        showInsightsModule: true,
      );

  GuardianSettingsPreferences copyWith({
    bool? notificationsEnabled,
    AlertSensitivity? alertSensitivity,
    bool? dailyDigestEnabled,
    bool? weeklyDigestEnabled,
    bool? showMedicationReminders,
    bool? showHydrationReminders,
    bool? showNutritionReminders,
    bool? showLocationUpdates,
    bool? linkedSeniorInfoVisible,
    bool? showCheckInMonitoring,
    bool? showIncidentMonitoring,
    bool? showInsightsModule,
  }) {
    return GuardianSettingsPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
      showMedicationReminders:
          showMedicationReminders ?? this.showMedicationReminders,
      showHydrationReminders:
          showHydrationReminders ?? this.showHydrationReminders,
      showNutritionReminders:
          showNutritionReminders ?? this.showNutritionReminders,
      showLocationUpdates: showLocationUpdates ?? this.showLocationUpdates,
      linkedSeniorInfoVisible:
          linkedSeniorInfoVisible ?? this.linkedSeniorInfoVisible,
      showCheckInMonitoring:
          showCheckInMonitoring ?? this.showCheckInMonitoring,
      showIncidentMonitoring:
          showIncidentMonitoring ?? this.showIncidentMonitoring,
      showInsightsModule: showInsightsModule ?? this.showInsightsModule,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'notificationsEnabled': notificationsEnabled,
        'alertSensitivity': alertSensitivity.name,
        'dailyDigestEnabled': dailyDigestEnabled,
        'weeklyDigestEnabled': weeklyDigestEnabled,
        'showMedicationReminders': showMedicationReminders,
        'showHydrationReminders': showHydrationReminders,
        'showNutritionReminders': showNutritionReminders,
        'showLocationUpdates': showLocationUpdates,
        'linkedSeniorInfoVisible': linkedSeniorInfoVisible,
        'showCheckInMonitoring': showCheckInMonitoring,
        'showIncidentMonitoring': showIncidentMonitoring,
        'showInsightsModule': showInsightsModule,
      };

  factory GuardianSettingsPreferences.fromJson(Map<String, dynamic> json) {
    final defaults = GuardianSettingsPreferences.defaults();
    return GuardianSettingsPreferences(
      notificationsEnabled: json['notificationsEnabled'] as bool? ??
          defaults.notificationsEnabled,
      alertSensitivity: _alertSensitivityFromRaw(
        json['alertSensitivity'] as String?,
        fallback: defaults.alertSensitivity,
      ),
      dailyDigestEnabled:
          json['dailyDigestEnabled'] as bool? ?? defaults.dailyDigestEnabled,
      weeklyDigestEnabled:
          json['weeklyDigestEnabled'] as bool? ?? defaults.weeklyDigestEnabled,
      showMedicationReminders: json['showMedicationReminders'] as bool? ??
          defaults.showMedicationReminders,
      showHydrationReminders: json['showHydrationReminders'] as bool? ??
          defaults.showHydrationReminders,
      showNutritionReminders: json['showNutritionReminders'] as bool? ??
          defaults.showNutritionReminders,
      showLocationUpdates:
          json['showLocationUpdates'] as bool? ?? defaults.showLocationUpdates,
      linkedSeniorInfoVisible: json['linkedSeniorInfoVisible'] as bool? ??
          defaults.linkedSeniorInfoVisible,
      showCheckInMonitoring: json['showCheckInMonitoring'] as bool? ??
          defaults.showCheckInMonitoring,
      showIncidentMonitoring: json['showIncidentMonitoring'] as bool? ??
          defaults.showIncidentMonitoring,
      showInsightsModule: json['showInsightsModule'] as bool? ??
          defaults.showInsightsModule,
    );
  }
}

ReminderIntensity _reminderIntensityFromRaw(
  String? raw, {
  required ReminderIntensity fallback,
}) =>
    switch (raw) {
      'low' => ReminderIntensity.low,
      'high' => ReminderIntensity.high,
      'normal' => ReminderIntensity.normal,
      _ => fallback,
    };

AlertSensitivity _alertSensitivityFromRaw(
  String? raw, {
  required AlertSensitivity fallback,
}) =>
    switch (raw) {
      'low' => AlertSensitivity.low,
      'high' => AlertSensitivity.high,
      'normal' => AlertSensitivity.normal,
      _ => fallback,
    };
