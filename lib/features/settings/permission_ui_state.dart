import 'package:flutter/material.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';

enum PermissionUiAction {
  none,
  request,
  openSettings,
}

class PermissionUiState {
  const PermissionUiState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final PermissionUiAction action;
}

PermissionUiState permissionUiStateFor(AppPermissionStatus? status) {
  return switch (status) {
    AppPermissionStatus.granted => const PermissionUiState(
        icon: Icons.check_circle_outline,
        title: 'Granted',
        detail: 'Feature access is enabled.',
        action: PermissionUiAction.none,
      ),
    AppPermissionStatus.denied => const PermissionUiState(
        icon: Icons.info_outline,
        title: 'Denied',
        detail: 'Allow access to enable this feature.',
        action: PermissionUiAction.request,
      ),
    AppPermissionStatus.permanentlyDenied => const PermissionUiState(
        icon: Icons.warning_amber_outlined,
        title: 'Permanently denied',
        detail: 'Open system settings to enable this permission.',
        action: PermissionUiAction.openSettings,
      ),
    AppPermissionStatus.restricted => const PermissionUiState(
        icon: Icons.warning_amber_outlined,
        title: 'Restricted',
        detail: 'This permission is restricted on this device profile.',
        action: PermissionUiAction.openSettings,
      ),
    AppPermissionStatus.limited => const PermissionUiState(
        icon: Icons.info_outline,
        title: 'Limited',
        detail: 'Permission is limited; full access may be required.',
        action: PermissionUiAction.request,
      ),
    null => const PermissionUiState(
        icon: Icons.help_outline,
        title: 'Unknown',
        detail: 'Permission status is loading.',
        action: PermissionUiAction.none,
      ),
  };
}
