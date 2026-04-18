import 'package:senior_companion/shared/models/notification_level.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

/// All known domain event categories produced by the application's modules.
///
/// Adding a new event type here forces every exhaustive switch in the codebase
/// to handle the new case at compile time.
enum AppEventType {
  checkInCompleted,
  checkInMissed,
  medicationTaken,
  medicationMissed,
  incidentSuspected,
  incidentConfirmed,
  incidentDismissed,
  emergencyTriggered,
  seniorStatusChanged,
  guardianAlertGenerated,
}

// ─────────────────────────────────────────────────────────────────────────────
// Base
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all domain events in the Senior Companion application.
///
/// Use [AppEventBus] to publish and subscribe to these events.
/// Switch exhaustively on the sealed subtypes to handle specific events:
///
/// ```dart
/// ref.read(appEventBusProvider).stream.listen((event) {
///   switch (event) {
///     case CheckInCompletedEvent(:final seniorId): ...
///     case MedicationTakenEvent(:final medicationName): ...
///     default: break;
///   }
/// });
/// ```
sealed class AppEvent {
  const AppEvent({
    required this.seniorId,
    required this.happenedAt,
  });

  /// The identifier of the senior this event is associated with.
  final String seniorId;

  /// When the event occurred. Always use UTC or a consistent timezone.
  final DateTime happenedAt;

  /// The category of this event, useful for filtering without pattern matching.
  AppEventType get type;
}

// ─────────────────────────────────────────────────────────────────────────────
// Check-in events
// ─────────────────────────────────────────────────────────────────────────────

final class CheckInCompletedEvent extends AppEvent {
  const CheckInCompletedEvent({
    required super.seniorId,
    required super.happenedAt,
  });

  @override
  AppEventType get type => AppEventType.checkInCompleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInCompletedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt);

  @override
  String toString() =>
      'CheckInCompletedEvent(seniorId: $seniorId, happenedAt: $happenedAt)';
}

final class CheckInMissedEvent extends AppEvent {
  const CheckInMissedEvent({
    required super.seniorId,
    required super.happenedAt,
    required this.windowLabel,
  });

  /// A human-readable label for the missed check-in window (e.g. 'Morning').
  final String windowLabel;

  @override
  AppEventType get type => AppEventType.checkInMissed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInMissedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt &&
          other.windowLabel == windowLabel;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt, windowLabel);

  @override
  String toString() => 'CheckInMissedEvent('
      'seniorId: $seniorId, '
      'happenedAt: $happenedAt, '
      'windowLabel: $windowLabel)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Medication events
// ─────────────────────────────────────────────────────────────────────────────

final class MedicationTakenEvent extends AppEvent {
  const MedicationTakenEvent({
    required super.seniorId,
    required super.happenedAt,
    required this.medicationName,
  });

  /// The display name of the medication that was confirmed taken.
  final String medicationName;

  @override
  AppEventType get type => AppEventType.medicationTaken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationTakenEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt &&
          other.medicationName == medicationName;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt, medicationName);

  @override
  String toString() => 'MedicationTakenEvent('
      'seniorId: $seniorId, '
      'happenedAt: $happenedAt, '
      'medicationName: $medicationName)';
}

final class MedicationMissedEvent extends AppEvent {
  const MedicationMissedEvent({
    required super.seniorId,
    required super.happenedAt,
    required this.medicationName,
  });

  /// The display name of the medication that was not confirmed.
  final String medicationName;

  @override
  AppEventType get type => AppEventType.medicationMissed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationMissedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt &&
          other.medicationName == medicationName;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt, medicationName);

  @override
  String toString() => 'MedicationMissedEvent('
      'seniorId: $seniorId, '
      'happenedAt: $happenedAt, '
      'medicationName: $medicationName)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Incident events
// ─────────────────────────────────────────────────────────────────────────────

final class IncidentSuspectedEvent extends AppEvent {
  const IncidentSuspectedEvent({
    required super.seniorId,
    required super.happenedAt,
    required this.confidenceScore,
  });

  /// A value between 0.0 and 1.0 indicating how likely an abnormal event
  /// occurred. This is NOT a guarantee — see incident vigilance positioning.
  final double confidenceScore;

  @override
  AppEventType get type => AppEventType.incidentSuspected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentSuspectedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt &&
          other.confidenceScore == confidenceScore;

  @override
  int get hashCode =>
      Object.hash(type, seniorId, happenedAt, confidenceScore);

  @override
  String toString() => 'IncidentSuspectedEvent('
      'seniorId: $seniorId, '
      'happenedAt: $happenedAt, '
      'confidenceScore: $confidenceScore)';
}

final class IncidentConfirmedEvent extends AppEvent {
  const IncidentConfirmedEvent({
    required super.seniorId,
    required super.happenedAt,
  });

  @override
  AppEventType get type => AppEventType.incidentConfirmed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentConfirmedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt);

  @override
  String toString() =>
      'IncidentConfirmedEvent(seniorId: $seniorId, happenedAt: $happenedAt)';
}

final class IncidentDismissedEvent extends AppEvent {
  const IncidentDismissedEvent({
    required super.seniorId,
    required super.happenedAt,
  });

  @override
  AppEventType get type => AppEventType.incidentDismissed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentDismissedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt);

  @override
  String toString() =>
      'IncidentDismissedEvent(seniorId: $seniorId, happenedAt: $happenedAt)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Emergency event
// ─────────────────────────────────────────────────────────────────────────────

final class EmergencyTriggeredEvent extends AppEvent {
  const EmergencyTriggeredEvent({
    required super.seniorId,
    required super.happenedAt,
  });

  @override
  AppEventType get type => AppEventType.emergencyTriggered;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyTriggeredEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt);

  @override
  String toString() =>
      'EmergencyTriggeredEvent(seniorId: $seniorId, happenedAt: $happenedAt)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Status and alert events
// ─────────────────────────────────────────────────────────────────────────────

final class SeniorStatusChangedEvent extends AppEvent {
  const SeniorStatusChangedEvent({
    required super.seniorId,
    required super.happenedAt,
    required this.newStatus,
  });

  /// The new computed global status for this senior.
  final SeniorGlobalStatus newStatus;

  @override
  AppEventType get type => AppEventType.seniorStatusChanged;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeniorStatusChangedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt &&
          other.newStatus == newStatus;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt, newStatus);

  @override
  String toString() => 'SeniorStatusChangedEvent('
      'seniorId: $seniorId, '
      'happenedAt: $happenedAt, '
      'newStatus: $newStatus)';
}

final class GuardianAlertGeneratedEvent extends AppEvent {
  const GuardianAlertGeneratedEvent({
    required super.seniorId,
    required super.happenedAt,
    required this.alertLevel,
  });

  /// The severity level of the alert generated for the guardian.
  final NotificationLevel alertLevel;

  @override
  AppEventType get type => AppEventType.guardianAlertGenerated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardianAlertGeneratedEvent &&
          other.seniorId == seniorId &&
          other.happenedAt == happenedAt &&
          other.alertLevel == alertLevel;

  @override
  int get hashCode => Object.hash(type, seniorId, happenedAt, alertLevel);

  @override
  String toString() => 'GuardianAlertGeneratedEvent('
      'seniorId: $seniorId, '
      'happenedAt: $happenedAt, '
      'alertLevel: $alertLevel)';
}