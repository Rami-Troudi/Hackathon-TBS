import 'package:senior_companion/shared/models/safe_zone.dart';

class SimulatedLocation {
  const SimulatedLocation({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.label,
  });

  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final String? label;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': updatedAt.toIso8601String(),
        'label': label,
      };

  factory SimulatedLocation.fromJson(Map<String, dynamic> json) =>
      SimulatedLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        label: json['label'] as String?,
      );
}

class SafeZoneStatus {
  const SafeZoneStatus({
    required this.location,
    required this.activeZone,
    required this.lastTransitionAt,
  });

  final SimulatedLocation? location;
  final SafeZone? activeZone;
  final DateTime? lastTransitionAt;

  bool get isInsideSafeZone => activeZone != null;
  String get zoneLabel => activeZone?.name ?? 'Outside safe zones';
}
