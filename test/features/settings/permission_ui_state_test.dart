import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/core/permissions/permission_service.dart';
import 'package:senior_companion/features/settings/permission_ui_state.dart';

void main() {
  test('maps permanently denied permission to open settings action', () {
    final state = permissionUiStateFor(AppPermissionStatus.permanentlyDenied);

    expect(state.title, 'Permanently denied');
    expect(state.action, PermissionUiAction.openSettings);
  });

  test('maps denied permission to request action', () {
    final state = permissionUiStateFor(AppPermissionStatus.denied);

    expect(state.title, 'Denied');
    expect(state.action, PermissionUiAction.request);
  });
}
