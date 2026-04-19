class SafeZone {
  const SafeZone({
    required this.id,
    required this.seniorId,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.isActive,
  });

  final String id;
  final String seniorId;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'seniorId': seniorId,
        'name': name,
        'centerLatitude': centerLatitude,
        'centerLongitude': centerLongitude,
        'radiusMeters': radiusMeters,
        'isActive': isActive,
      };

  factory SafeZone.fromJson(Map<String, dynamic> json) => SafeZone(
        id: json['id'] as String,
        seniorId: json['seniorId'] as String,
        name: json['name'] as String,
        centerLatitude: (json['centerLatitude'] as num).toDouble(),
        centerLongitude: (json['centerLongitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        isActive: json['isActive'] as bool? ?? true,
      );
}
