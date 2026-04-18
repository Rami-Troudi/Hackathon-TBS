import 'package:senior_companion/core/events/app_event.dart';

enum GuardianTimelineFilter {
  all,
  checkIns,
  medication,
  wellbeing,
  location,
  incidents,
  emergency,
}

extension GuardianTimelineFilterX on GuardianTimelineFilter {
  String get label => switch (this) {
        GuardianTimelineFilter.all => 'All',
        GuardianTimelineFilter.checkIns => 'Check-ins',
        GuardianTimelineFilter.medication => 'Medication',
        GuardianTimelineFilter.wellbeing => 'Wellbeing',
        GuardianTimelineFilter.location => 'Location',
        GuardianTimelineFilter.incidents => 'Incidents',
        GuardianTimelineFilter.emergency => 'Emergency',
      };

  Set<AppEventType>? get eventTypes => switch (this) {
        GuardianTimelineFilter.all => null,
        GuardianTimelineFilter.checkIns => const <AppEventType>{
            AppEventType.checkInCompleted,
            AppEventType.checkInMissed,
          },
        GuardianTimelineFilter.medication => const <AppEventType>{
            AppEventType.medicationTaken,
            AppEventType.medicationMissed,
          },
        GuardianTimelineFilter.wellbeing => const <AppEventType>{
            AppEventType.hydrationCompleted,
            AppEventType.hydrationMissed,
            AppEventType.mealCompleted,
            AppEventType.mealMissed,
          },
        GuardianTimelineFilter.location => const <AppEventType>{
            AppEventType.safeZoneEntered,
            AppEventType.safeZoneExited,
          },
        GuardianTimelineFilter.incidents => const <AppEventType>{
            AppEventType.incidentSuspected,
            AppEventType.incidentConfirmed,
            AppEventType.incidentDismissed,
          },
        GuardianTimelineFilter.emergency => const <AppEventType>{
            AppEventType.emergencyTriggered,
          },
      };
}
