import 'package:flutter/material.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    required this.state,
  });

  final AppConnectivityState state;

  @override
  Widget build(BuildContext context) {
    final tone = switch (state) {
      AppConnectivityState.online => AppCardTone.surface,
      AppConnectivityState.degraded => AppCardTone.warning,
      AppConnectivityState.offline => AppCardTone.danger,
    };
    final icon = switch (state) {
      AppConnectivityState.online => Icons.cloud_done_outlined,
      AppConnectivityState.degraded => Icons.cloud_queue_outlined,
      AppConnectivityState.offline => Icons.cloud_off_outlined,
    };
    final title = switch (state) {
      AppConnectivityState.online => 'Connected',
      AppConnectivityState.degraded => 'Degraded connectivity',
      AppConnectivityState.offline => 'Offline mode',
    };
    final message = switch (state) {
      AppConnectivityState.online =>
        'Network-dependent features are available.',
      AppConnectivityState.degraded =>
        'Using local data first. Some updates may appear later.',
      AppConnectivityState.offline =>
        'Showing local data only until connectivity is restored.',
    };

    return AppCard(
      tone: tone,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          Gaps.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Gaps.v4,
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
