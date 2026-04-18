import 'package:senior_companion/core/events/app_event.dart';

enum EventSeverity { info, warning, critical }

class PersistedEventRecord {
  const PersistedEventRecord({
    required this.id,
    required this.seniorId,
    required this.type,
    required this.happenedAt,
    required this.createdAt,
    required this.source,
    required this.severity,
    required this.payload,
  });

  final String id;
  final String seniorId;
  final AppEventType type;
  final DateTime happenedAt;
  final DateTime createdAt;
  final String source;
  final EventSeverity severity;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'seniorId': seniorId,
        'type': type.name,
        'happenedAt': happenedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'source': source,
        'severity': severity.name,
        'payload': payload,
      };

  factory PersistedEventRecord.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return PersistedEventRecord(
      id: json['id'] as String,
      seniorId: json['seniorId'] as String,
      type: appEventTypeFromRaw(json['type'] as String),
      happenedAt: DateTime.parse(json['happenedAt'] as String),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['happenedAt']) as String,
      ),
      source: (json['source'] as String?) ?? 'unknown',
      severity: eventSeverityFromRaw(json['severity'] as String?),
      payload: payload is Map
          ? Map<String, dynamic>.from(payload.cast<dynamic, dynamic>())
          : const <String, dynamic>{},
    );
  }

  PersistedEventRecord copyWith({
    String? id,
    String? seniorId,
    AppEventType? type,
    DateTime? happenedAt,
    DateTime? createdAt,
    String? source,
    EventSeverity? severity,
    Map<String, dynamic>? payload,
  }) {
    return PersistedEventRecord(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      type: type ?? this.type,
      happenedAt: happenedAt ?? this.happenedAt,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      severity: severity ?? this.severity,
      payload: payload ?? this.payload,
    );
  }

  static String nextId({DateTime? now}) {
    final timestamp =
        (now ?? DateTime.now().toUtc()).microsecondsSinceEpoch.toString();
    _sequence = (_sequence + 1) % 1000000;
    return 'evt-$timestamp-$_sequence';
  }

  static int _sequence = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistedEventRecord &&
          other.id == id &&
          other.seniorId == seniorId &&
          other.type == type &&
          other.happenedAt == happenedAt &&
          other.createdAt == createdAt &&
          other.source == source &&
          other.severity == severity &&
          _mapsEqual(other.payload, payload);

  @override
  int get hashCode => Object.hash(
        id,
        seniorId,
        type,
        happenedAt,
        createdAt,
        source,
        severity,
        Object.hashAll(
          payload.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );
}

AppEventType appEventTypeFromRaw(String raw) => switch (raw) {
      'checkInCompleted' => AppEventType.checkInCompleted,
      'checkInMissed' => AppEventType.checkInMissed,
      'medicationTaken' => AppEventType.medicationTaken,
      'medicationMissed' => AppEventType.medicationMissed,
      'incidentSuspected' => AppEventType.incidentSuspected,
      'incidentConfirmed' => AppEventType.incidentConfirmed,
      'incidentDismissed' => AppEventType.incidentDismissed,
      'emergencyTriggered' => AppEventType.emergencyTriggered,
      'seniorStatusChanged' => AppEventType.seniorStatusChanged,
      'guardianAlertGenerated' => AppEventType.guardianAlertGenerated,
      _ => throw FormatException('Unknown event type: $raw'),
    };

EventSeverity eventSeverityFromRaw(String? raw) => switch (raw) {
      'critical' => EventSeverity.critical,
      'warning' => EventSeverity.warning,
      _ => EventSeverity.info,
    };

extension AppEventTypeTimelineLabelX on AppEventType {
  String get timelineLabel => switch (this) {
        AppEventType.checkInCompleted => 'Check-in completed',
        AppEventType.checkInMissed => 'Check-in missed',
        AppEventType.medicationTaken => 'Medication taken',
        AppEventType.medicationMissed => 'Medication missed',
        AppEventType.incidentSuspected => 'Incident suspected',
        AppEventType.incidentConfirmed => 'Incident confirmed',
        AppEventType.incidentDismissed => 'Incident dismissed',
        AppEventType.emergencyTriggered => 'Emergency triggered',
        AppEventType.seniorStatusChanged => 'Status changed',
        AppEventType.guardianAlertGenerated => 'Guardian alert',
      };
}

bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
