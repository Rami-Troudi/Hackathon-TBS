import 'package:permission_handler/permission_handler.dart';
import 'package:senior_companion/core/logging/app_logger.dart';

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

abstract class PermissionService {
  Future<AppPermissionStatus> notificationStatus();
  Future<AppPermissionStatus> requestNotificationPermission();
  Future<AppPermissionStatus> locationStatus();
  Future<AppPermissionStatus> requestLocationPermission();
  Future<bool> openSystemSettings();
}

class PermissionHandlerPermissionService implements PermissionService {
  PermissionHandlerPermissionService({
    required this.logger,
  });

  final AppLogger logger;

  AppPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isLimited) return AppPermissionStatus.limited;
    return AppPermissionStatus.denied;
  }

  @override
  Future<AppPermissionStatus> notificationStatus() async {
    final status = await Permission.notification.status;
    return _mapStatus(status);
  }

  @override
  Future<AppPermissionStatus> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    final mapped = _mapStatus(status);
    logger.info('Notification permission status: $mapped');
    return mapped;
  }

  @override
  Future<AppPermissionStatus> locationStatus() async {
    final status = await Permission.locationWhenInUse.status;
    return _mapStatus(status);
  }

  @override
  Future<AppPermissionStatus> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    final mapped = _mapStatus(status);
    logger.info('Location permission status: $mapped');
    return mapped;
  }

  @override
  Future<bool> openSystemSettings() async {
    final opened = await openAppSettings();
    logger.info('Open system settings requested: $opened');
    return opened;
  }
}
