import 'dart:math';

import 'package:hive/hive.dart';
import 'package:senior_companion/core/events/app_event.dart';
import 'package:senior_companion/core/events/app_event_recorder.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/core/repositories/event_repository.dart';
import 'package:senior_companion/core/repositories/safe_zone_repository.dart';
import 'package:senior_companion/core/storage/hive_box_names.dart';
import 'package:senior_companion/core/storage/hive_initializer.dart';
import 'package:senior_companion/shared/models/safe_zone.dart';
import 'package:senior_companion/shared/models/safe_zone_status.dart';

class LocalSafeZoneRepository implements SafeZoneRepository {
  const LocalSafeZoneRepository({
    required this.hiveInitializer,
    required this.eventRepository,
    required this.eventRecorder,
  });

  final HiveInitializer hiveInitializer;
  final EventRepository eventRepository;
  final AppEventRecorder eventRecorder;

  @override
  Future<List<SafeZone>> getSafeZonesForSenior(String seniorId) async {
    return _zonesBox.values
        .map((entry) => SafeZone.fromJson(Map<String, dynamic>.from(entry)))
        .where((zone) => zone.seniorId == seniorId && zone.isActive)
        .toList(growable: false);
  }

  @override
  Future<void> saveSafeZone(SafeZone zone) async {
    await _zonesBox.put(zone.id, zone.toJson());
  }

  @override
  Future<void> deleteSafeZone({
    required String seniorId,
    required String zoneId,
  }) async {
    final current = _zonesBox.get(zoneId);
    if (current == null) return;
    final zone = SafeZone.fromJson(Map<String, dynamic>.from(current));
    if (zone.seniorId != seniorId) return;
    await _zonesBox.delete(zoneId);
  }

  @override
  Future<void> seedDefaultZonesIfNeeded(String seniorId) async {
    final zones = await getSafeZonesForSenior(seniorId);
    if (zones.isNotEmpty) return;
    await saveSafeZone(
      SafeZone(
        id: '$seniorId-zone-home',
        seniorId: seniorId,
        name: 'Home',
        centerLatitude: 36.8065,
        centerLongitude: 10.1815,
        radiusMeters: 250,
        isActive: true,
      ),
    );
    await saveSafeZone(
      SafeZone(
        id: '$seniorId-zone-pharmacy',
        seniorId: seniorId,
        name: 'Nearby pharmacy',
        centerLatitude: 36.8090,
        centerLongitude: 10.1705,
        radiusMeters: 180,
        isActive: true,
      ),
    );
  }

  @override
  Future<SafeZoneStatus> getCurrentStatus(String seniorId) async {
    await seedDefaultZonesIfNeeded(seniorId);
    final zones = await getSafeZonesForSenior(seniorId);
    final runtime = _readRuntimeState(seniorId);
    final activeZone = runtime.currentZoneId == null
        ? null
        : _findZoneById(zones, runtime.currentZoneId!);
    return SafeZoneStatus(
      location: runtime.location,
      activeZone: activeZone,
      lastTransitionAt: runtime.lastTransitionAt,
    );
  }

  @override
  Future<SafeZoneStatus> updateSimulatedLocation(
    String seniorId, {
    required double latitude,
    required double longitude,
    String? label,
    DateTime? now,
  }) async {
    await seedDefaultZonesIfNeeded(seniorId);
    final reference = (now ?? DateTime.now()).toLocal();
    final zones = await getSafeZonesForSenior(seniorId);
    final runtime = _readRuntimeState(seniorId);
    final nextLocation = SimulatedLocation(
      latitude: latitude,
      longitude: longitude,
      label: label,
      updatedAt: reference.toUtc(),
    );
    final nextZone = _findContainingZone(
      zones,
      latitude: latitude,
      longitude: longitude,
    );
    final previousZone = runtime.currentZoneId == null
        ? null
        : _findZoneById(zones, runtime.currentZoneId!);

    DateTime? transitionAt = runtime.lastTransitionAt;
    if (runtime.currentZoneId != nextZone?.id) {
      transitionAt = reference.toUtc();
      final previousZoneName = previousZone?.name ?? runtime.currentZoneName;
      if (runtime.currentZoneId != null && previousZoneName != null) {
        await eventRecorder.publishAndPersist(
          SafeZoneExitedEvent(
            seniorId: seniorId,
            happenedAt: reference.toUtc(),
            zoneId: runtime.currentZoneId!,
            zoneName: previousZoneName,
          ),
          source: 'guardian.location',
        );
      }
      if (nextZone != null) {
        await eventRecorder.publishAndPersist(
          SafeZoneEnteredEvent(
            seniorId: seniorId,
            happenedAt: reference.toUtc(),
            zoneId: nextZone.id,
            zoneName: nextZone.name,
          ),
          source: 'guardian.location',
        );
      }
    }

    await _writeRuntimeState(
      seniorId,
      _SafeZoneRuntimeState(
        location: nextLocation,
        currentZoneId: nextZone?.id,
        currentZoneName: nextZone?.name,
        lastTransitionAt: transitionAt,
      ),
    );
    return SafeZoneStatus(
      location: nextLocation,
      activeZone: nextZone,
      lastTransitionAt: transitionAt,
    );
  }

  @override
  Future<List<PersistedEventRecord>> fetchRecentZoneEvents(
    String seniorId, {
    int limit = 20,
  }) {
    return eventRepository.fetchTimelineForSenior(
      seniorId,
      order: TimelineOrder.newestFirst,
      types: const <AppEventType>{
        AppEventType.safeZoneEntered,
        AppEventType.safeZoneExited,
      },
      limit: limit,
    );
  }

  SafeZone? _findContainingZone(
    List<SafeZone> zones, {
    required double latitude,
    required double longitude,
  }) {
    SafeZone? nearest;
    double? nearestDistance;
    for (final zone in zones) {
      final distance = _distanceMeters(
        latitude,
        longitude,
        zone.centerLatitude,
        zone.centerLongitude,
      );
      if (distance > zone.radiusMeters) continue;
      if (nearest == null || distance < nearestDistance!) {
        nearest = zone;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  SafeZone? _findZoneById(List<SafeZone> zones, String zoneId) {
    for (final zone in zones) {
      if (zone.id == zoneId) return zone;
    }
    return null;
  }

  double _distanceMeters(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(toLat - fromLat);
    final dLng = _degreesToRadians(toLng - fromLng);
    final a = pow(sin(dLat / 2), 2) +
        cos(_degreesToRadians(fromLat)) *
            cos(_degreesToRadians(toLat)) *
            pow(sin(dLng / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180.0;

  _SafeZoneRuntimeState _readRuntimeState(String seniorId) {
    final raw = _stateBox.get(seniorId);
    if (raw == null) return const _SafeZoneRuntimeState();
    return _SafeZoneRuntimeState.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> _writeRuntimeState(
    String seniorId,
    _SafeZoneRuntimeState state,
  ) async {
    await _stateBox.put(seniorId, state.toJson());
  }

  Box<Map> get _zonesBox => hiveInitializer.box(HiveBoxNames.safeZones);
  Box<Map> get _stateBox => hiveInitializer.box(HiveBoxNames.safeZoneState);
}

class _SafeZoneRuntimeState {
  const _SafeZoneRuntimeState({
    this.location,
    this.currentZoneId,
    this.currentZoneName,
    this.lastTransitionAt,
  });

  final SimulatedLocation? location;
  final String? currentZoneId;
  final String? currentZoneName;
  final DateTime? lastTransitionAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'location': location?.toJson(),
        'currentZoneId': currentZoneId,
        'currentZoneName': currentZoneName,
        'lastTransitionAt': lastTransitionAt?.toIso8601String(),
      };

  factory _SafeZoneRuntimeState.fromJson(Map<String, dynamic> json) =>
      _SafeZoneRuntimeState(
        location: json['location'] is Map
            ? SimulatedLocation.fromJson(
                Map<String, dynamic>.from(json['location'] as Map),
              )
            : null,
        currentZoneId: json['currentZoneId'] as String?,
        currentZoneName: json['currentZoneName'] as String?,
        lastTransitionAt: json['lastTransitionAt'] == null
            ? null
            : DateTime.parse(json['lastTransitionAt'] as String),
      );
}
