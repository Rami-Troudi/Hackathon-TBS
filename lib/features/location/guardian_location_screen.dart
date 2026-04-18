import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/features/location/guardian_location_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/safe_zone.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';

class GuardianLocationScreen extends ConsumerWidget {
  const GuardianLocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(guardianLocationDataProvider);
    return AppScaffoldShell(
      title: 'Location & safe zones',
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load location: $error')),
        data: (data) {
          final seniorId = data.seniorId;
          if (seniorId == null) {
            return const Center(child: Text('No active senior context found.'));
          }
          final profileName = data.seniorProfile?.displayName ?? 'Senior';
          final status = data.status;
          final location = status.location;
          final zoneLabel = status.zoneLabel;
          return ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profileName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddZoneDialog(context, ref, seniorId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add zone'),
                  ),
                ],
              ),
              Gaps.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.isInsideSafeZone
                            ? 'Inside safe zone'
                            : 'Outside safe zone',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Gaps.v4,
                      Text('Current area: $zoneLabel'),
                      Text(
                        location == null
                            ? 'Location not simulated yet'
                            : 'Location: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.v16,
              Text(
                'Safe zones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Gaps.v8,
              if (data.zones.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No safe zones configured.'),
                  ),
                )
              else
                ...data.zones.map(
                  (zone) => Card(
                    child: ListTile(
                      title: Text(zone.name),
                      subtitle: Text(
                        'Radius ${zone.radiusMeters.round()}m • ${zone.centerLatitude.toStringAsFixed(4)}, ${zone.centerLongitude.toStringAsFixed(4)}',
                      ),
                      onTap: () => _simulateMoveToZone(ref, seniorId, zone),
                      trailing: IconButton(
                        onPressed: () => _deleteZone(ref, seniorId, zone.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
              Gaps.v8,
              OutlinedButton.icon(
                onPressed: () => _simulateOutside(ref, seniorId, data.zones),
                icon: const Icon(Icons.my_location),
                label: const Text('Simulate outside all zones'),
              ),
              Gaps.v16,
              Text(
                'Recent location events',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Gaps.v8,
              if (data.recentEvents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No location events yet.'),
                  ),
                )
              else
                ...data.recentEvents.take(15).map(
                      (event) => Card(
                        child: ListTile(
                          title: Text(event.type.timelineLabel),
                          subtitle: Text(formatEventDetail(event)),
                          trailing: Icon(iconForEventType(event.type)),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _simulateMoveToZone(
    WidgetRef ref,
    String seniorId,
    SafeZone zone,
  ) async {
    await ref.read(safeZoneRepositoryProvider).updateSimulatedLocation(
          seniorId,
          latitude: zone.centerLatitude,
          longitude: zone.centerLongitude,
          label: zone.name,
        );
    ref.invalidate(guardianLocationDataProvider);
  }

  Future<void> _simulateOutside(
    WidgetRef ref,
    String seniorId,
    List<SafeZone> zones,
  ) async {
    final baselineLat =
        zones.isEmpty ? 36.8065 : zones.first.centerLatitude + 0.03;
    final baselineLng =
        zones.isEmpty ? 10.1815 : zones.first.centerLongitude + 0.03;
    await ref.read(safeZoneRepositoryProvider).updateSimulatedLocation(
          seniorId,
          latitude: baselineLat,
          longitude: baselineLng,
          label: 'Outside safe zones',
        );
    ref.invalidate(guardianLocationDataProvider);
  }

  Future<void> _deleteZone(
    WidgetRef ref,
    String seniorId,
    String zoneId,
  ) async {
    await ref.read(safeZoneRepositoryProvider).deleteSafeZone(
          seniorId: seniorId,
          zoneId: zoneId,
        );
    ref.invalidate(guardianLocationDataProvider);
  }

  Future<void> _showAddZoneDialog(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
  ) async {
    final nameController = TextEditingController();
    final latController = TextEditingController(text: '36.8065');
    final lngController = TextEditingController(text: '10.1815');
    final radiusController = TextEditingController(text: '200');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add safe zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Zone name'),
              ),
              TextField(
                controller: latController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lngController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              TextField(
                controller: radiusController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final name = nameController.text.trim();
    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());
    final radius = double.tryParse(radiusController.text.trim());
    if (name.isEmpty || lat == null || lng == null || radius == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all zone fields correctly.')),
      );
      return;
    }

    final zone = SafeZone(
      id: _zoneId(seniorId, name),
      seniorId: seniorId,
      name: name,
      centerLatitude: lat,
      centerLongitude: lng,
      radiusMeters: radius,
      isActive: true,
    );
    await ref.read(safeZoneRepositoryProvider).saveSafeZone(zone);
    await _setLocationAndRefresh(
      ref,
      seniorId,
      latitude: lat,
      longitude: lng,
      label: name,
    );
  }

  Future<void> _setLocationAndRefresh(
    WidgetRef ref,
    String seniorId, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    await ref.read(safeZoneRepositoryProvider).updateSimulatedLocation(
          seniorId,
          latitude: latitude,
          longitude: longitude,
          label: label,
        );
    ref.invalidate(guardianLocationDataProvider);
  }

  String _zoneId(String seniorId, String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return '$seniorId-zone-$normalized-${DateTime.now().millisecondsSinceEpoch}';
  }
}
