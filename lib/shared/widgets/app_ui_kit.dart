import 'package:flutter/material.dart';
import 'package:senior_companion/app/theme/app_colors.dart';
import 'package:senior_companion/core/events/persisted_event_record.dart';
import 'package:senior_companion/features/guardian/guardian_ui_helpers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/models/guardian_alert.dart';
import 'package:senior_companion/shared/models/guardian_alert_state.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';

enum AppCardTone {
  surface,
  sage,
  clay,
  warning,
  danger,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tone = AppCardTone.surface,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _cardColors(tone);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2A1A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        onTap: onTap,
        child: card,
      ),
    );
  }

  _CardColors _cardColors(AppCardTone tone) => switch (tone) {
        AppCardTone.sage => const _CardColors(
            background: AppColors.primarySoft,
            border: Color(0xFFD1E4D6),
          ),
        AppCardTone.clay => const _CardColors(
            background: AppColors.accentSoft,
            border: Color(0xFFECCDBA),
          ),
        AppCardTone.warning => const _CardColors(
            background: Color(0xFFFFF2D7),
            border: Color(0xFFEACB83),
          ),
        AppCardTone.danger => const _CardColors(
            background: Color(0xFFFBE4E1),
            border: Color(0xFFEAB4AC),
          ),
        AppCardTone.surface => const _CardColors(
            background: AppColors.surface,
            border: AppColors.divider,
          ),
      };
}

class _CardColors {
  const _CardColors({
    required this.background,
    required this.border,
  });

  final Color background;
  final Color border;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
  });

  final SeniorGlobalStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SeniorGlobalStatus.ok => AppColors.success,
      SeniorGlobalStatus.watch => AppColors.warning,
      SeniorGlobalStatus.actionRequired => AppColors.critical,
    };
    final background = switch (status) {
      SeniorGlobalStatus.ok => AppColors.primarySoft,
      SeniorGlobalStatus.watch => const Color(0xFFFFF2D7),
      SeniorGlobalStatus.actionRequired => const Color(0xFFFBE4E1),
    };
    return _Pill(
      label: status.label,
      foreground: color,
      background: background,
      dot: true,
    );
  }
}

class SeverityChip extends StatelessWidget {
  const SeverityChip({
    super.key,
    required this.severity,
  });

  final GuardianAlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      GuardianAlertSeverity.info => AppColors.info,
      GuardianAlertSeverity.warning => AppColors.warning,
      GuardianAlertSeverity.critical => AppColors.critical,
    };
    final background = switch (severity) {
      GuardianAlertSeverity.info => const Color(0xFFE5EEF8),
      GuardianAlertSeverity.warning => const Color(0xFFFFF2D7),
      GuardianAlertSeverity.critical => const Color(0xFFFBE4E1),
    };
    return _Pill(
      label: severity.label,
      foreground: color,
      background: background,
    );
  }
}

class EventSeverityChip extends StatelessWidget {
  const EventSeverityChip({
    super.key,
    required this.severity,
  });

  final EventSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      EventSeverity.info => AppColors.info,
      EventSeverity.warning => AppColors.warning,
      EventSeverity.critical => AppColors.critical,
    };
    final background = switch (severity) {
      EventSeverity.info => const Color(0xFFE5EEF8),
      EventSeverity.warning => const Color(0xFFFFF2D7),
      EventSeverity.critical => const Color(0xFFFBE4E1),
    };
    return _Pill(
      label: severity.name,
      foreground: color,
      background: background,
    );
  }
}

class StateChip extends StatelessWidget {
  const StateChip({
    super.key,
    required this.state,
  });

  final GuardianAlertState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      GuardianAlertState.active => AppColors.primary,
      GuardianAlertState.acknowledged => AppColors.info,
      GuardianAlertState.resolved => AppColors.success,
    };
    final background = switch (state) {
      GuardianAlertState.active => AppColors.primarySoft,
      GuardianAlertState.acknowledged => const Color(0xFFE5EEF8),
      GuardianAlertState.resolved => AppColors.primarySoft,
    };
    return _Pill(
      label: state.label,
      foreground: color,
      background: background,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
    this.dot = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            Gaps.h8,
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

enum BigActionTone {
  primary,
  destructive,
  soft,
}

class BigAction extends StatelessWidget {
  const BigAction({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.tone = BigActionTone.primary,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final BigActionTone tone;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = switch (tone) {
      BigActionTone.primary => AppColors.primary,
      BigActionTone.destructive => AppColors.critical,
      BigActionTone.soft => AppColors.surface,
    };
    final foreground = switch (tone) {
      BigActionTone.soft => AppColors.textPrimary,
      _ => AppColors.surface,
    };
    final iconBackground = switch (tone) {
      BigActionTone.soft => AppColors.primarySoft,
      _ => Colors.white.withOpacity(0.16),
    };

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: double.infinity,
        height: 132,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: foreground, size: 30),
                  ),
                  Gaps.h16,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: foreground),
                        ),
                        Gaps.v4,
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: foreground.withOpacity(0.86)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyStateBlock extends StatelessWidget {
  const EmptyStateBlock({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.more_horiz,
    this.action,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          Gaps.v16,
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Gaps.v4,
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[
            Gaps.v16,
            action!,
          ],
        ],
      ),
    );
  }
}

class MonitoringCard extends StatelessWidget {
  const MonitoringCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          Gaps.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Gaps.v4,
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class TimelineEventTile extends StatelessWidget {
  const TimelineEventTile({
    super.key,
    required this.event,
  });

  final PersistedEventRecord event;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              iconForEventType(event.type),
              color: AppColors.primary,
              size: 22,
            ),
          ),
          Gaps.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.type.timelineLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    EventSeverityChip(severity: event.severity),
                  ],
                ),
                Gaps.v4,
                Text(
                  formatLocalTime(event.happenedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Gaps.v8,
                Text(
                  formatEventDetail(event),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertListCard extends StatelessWidget {
  const AlertListCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
    required this.onOpenTimeline,
    required this.onOpenMonitoring,
  });

  final GuardianAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenMonitoring;

  @override
  Widget build(BuildContext context) {
    final tone = switch (alert.severity) {
      GuardianAlertSeverity.info => AppCardTone.surface,
      GuardianAlertSeverity.warning => AppCardTone.warning,
      GuardianAlertSeverity.critical => AppCardTone.danger,
    };

    return AppCard(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SeverityChip(severity: alert.severity),
            ],
          ),
          Gaps.v8,
          Row(
            children: [
              StateChip(state: alert.state),
              Gaps.h8,
              Text(
                '${formatLocalDay(alert.happenedAt)} ${formatLocalTime(alert.happenedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Gaps.v12,
          Text(alert.explanation),
          Gaps.v12,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (onAcknowledge != null)
                FilledButton.tonal(
                  onPressed: onAcknowledge,
                  child: const Text('Acknowledge'),
                ),
              if (onResolve != null)
                OutlinedButton(
                  onPressed: onResolve,
                  child: const Text('Resolve'),
                ),
              TextButton(
                onPressed: onOpenTimeline,
                child: const Text('Timeline'),
              ),
              TextButton(
                onPressed: onOpenMonitoring,
                child: const Text('Monitoring'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
