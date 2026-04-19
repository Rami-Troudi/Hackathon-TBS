import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/app/router/app_routes.dart';
import 'package:senior_companion/core/connectivity/connectivity_state_service.dart';
import 'package:senior_companion/features/senior/senior_home_providers.dart';
import 'package:senior_companion/shared/constants/app_spacing.dart';
import 'package:senior_companion/shared/localization/app_tr.dart';
import 'package:senior_companion/shared/models/check_in_state.dart';
import 'package:senior_companion/shared/models/dashboard_summary.dart';
import 'package:senior_companion/shared/models/incident_flow_state.dart';
import 'package:senior_companion/shared/models/medication_reminder.dart';
import 'package:senior_companion/shared/models/senior_global_status.dart';
import 'package:senior_companion/shared/widgets/app_scaffold_shell.dart';
import 'package:senior_companion/shared/widgets/app_ui_kit.dart';
import 'package:senior_companion/shared/widgets/connectivity_banner.dart';

class SeniorHomeScreen extends ConsumerStatefulWidget {
  const SeniorHomeScreen({super.key});

  @override
  ConsumerState<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends ConsumerState<SeniorHomeScreen> {
  String? _lastPromptToken;

  @override
  Widget build(BuildContext context) {
    final seniorHomeAsync = ref.watch(seniorHomeDataProvider);
    return AppScaffoldShell(
      title: tr(context, fr: 'Aujourd’hui', en: 'Today', ar: 'اليوم'),
      role: AppShellRole.senior,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: tr(
            context,
            fr: 'Paramètres',
            en: 'Settings',
            ar: 'الإعدادات',
          ),
        ),
      ],
      child: seniorHomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(
              child: Text(
                tr(
                  context,
                  fr: 'Impossible de charger l’accueil senior : $error',
                  en: 'Could not load senior home: $error',
                  ar: 'تعذر تحميل شاشة المسن: $error',
                ),
              ),
            ),
        data: (data) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUrgentPromptIfNeeded(context, data);
          });
          return _SeniorHomeContent(data: data);
        },
      ),
    );
  }

  Future<void> _showUrgentPromptIfNeeded(
    BuildContext context,
    SeniorHomeData data,
  ) async {
    if (!mounted || data.activeSeniorId == null) return;
    final reminder = data.nextReminder;
    final promptToken =
        '${data.incidentState.status.name}-${data.incidentState.openConfirmedIncidents}-${data.incidentState.openSuspectedIncidents}-${data.checkInState.status.name}-${reminder?.plan.id}-${reminder?.status.name}';
    if (_lastPromptToken == promptToken) return;

    if (data.settings.incidentModuleEnabled &&
        (data.incidentState.status == IncidentFlowStatus.suspected ||
            data.incidentState.status == IncidentFlowStatus.confirmed)) {
      _lastPromptToken = promptToken;
      final result = await showDialog<_IncidentPromptResult>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => IncidentCountdownDialog(
          title: tr(
            context,
            fr: 'Vous allez bien ?',
            en: 'Are you okay?',
            ar: 'هل أنت بخير؟',
          ),
          message: tr(
            context,
            fr:
                'Un incident a été détecté. Répondez dans 60 secondes pour éviter l’escalade d’urgence.',
            en:
                'An incident was detected. Respond within 60 seconds to avoid emergency escalation.',
            ar:
                'تم رصد حادثة. استجب خلال 60 ثانية لتفادي تصعيد الطوارئ.',
          ),
          okLabel: tr(context, fr: 'Oui, je vais bien', en: 'Yes, I am okay', ar: 'نعم، أنا بخير'),
          helpLabel: tr(context, fr: 'J’ai besoin d’aide', en: 'I need help', ar: 'أحتاج مساعدة'),
        ),
      );
      if (!mounted) return;
      if (result == _IncidentPromptResult.ok) {
        await ref.read(incidentRepositoryProvider).dismissIncident(
              data.activeSeniorId!,
            );
      } else {
        await ref.read(incidentRepositoryProvider).requestImmediateHelp(
              data.activeSeniorId!,
            );
      }
      ref.invalidate(seniorHomeDataProvider);
      return;
    }

    if (data.settings.checkInModuleEnabled &&
        data.checkInState.status != CheckInStatus.completed) {
      _lastPromptToken = promptToken;
      final yes = await _showSeniorPrompt(
        context,
        title: tr(
          context,
          fr: 'Vous allez bien ?',
          en: 'Are you okay?',
          ar: 'هل أنت بخير؟',
        ),
        body: tr(
          context,
          fr: 'Confirmez votre check-in quotidien maintenant.',
          en: 'Please confirm your daily check-in now.',
          ar: 'يرجى تأكيد تسجيل الحضور اليومي الآن.',
        ),
        yesLabel: tr(context, fr: 'Oui', en: 'Yes', ar: 'نعم'),
        noLabel: tr(context, fr: 'Non', en: 'No', ar: 'لا'),
      );
      if (!mounted) return;
      if (yes == true) {
        await ref
            .read(checkInRepositoryProvider)
            .markCheckInCompleted(data.activeSeniorId!);
      } else if (yes == false) {
        await ref
            .read(checkInRepositoryProvider)
            .markNeedHelp(data.activeSeniorId!);
      }
      ref.invalidate(seniorHomeDataProvider);
      return;
    }

    if (data.settings.medicationModuleEnabled &&
        reminder != null &&
        reminder.status == MedicationReminderStatus.pending) {
      _lastPromptToken = promptToken;
      final yes = await _showSeniorPrompt(
        context,
        title: tr(
          context,
          fr: 'Rappel médicament',
          en: 'Medication reminder',
          ar: 'تذكير الدواء',
        ),
        body: tr(
          context,
          fr:
              'Avez-vous pris ${reminder.plan.medicationName} (${reminder.slotLabel}) ?',
          en:
              'Did you take ${reminder.plan.medicationName} (${reminder.slotLabel})?',
          ar:
              'هل تناولت ${reminder.plan.medicationName} (${reminder.slotLabel})؟',
        ),
        yesLabel: tr(context, fr: 'Pris', en: 'Taken', ar: 'تم'),
        noLabel: tr(context, fr: 'Pas encore', en: 'Not yet', ar: 'ليس بعد'),
      );
      if (!mounted) return;
      if (yes == true) {
        await ref.read(medicationRepositoryProvider).markMedicationTaken(
              data.activeSeniorId!,
              planId: reminder.plan.id,
            );
      } else if (yes == false) {
        await ref.read(medicationRepositoryProvider).markMedicationMissed(
              data.activeSeniorId!,
              planId: reminder.plan.id,
            );
      }
      ref.invalidate(seniorHomeDataProvider);
    }
  }

  Future<bool?> _showSeniorPrompt(
    BuildContext context, {
    required String title,
    required String body,
    required String yesLabel,
    required String noLabel,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: tr(
        context,
        fr: 'Alerte senior',
        en: 'Senior prompt',
        ar: 'تنبيه للمسن',
      ),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.notifications_active_outlined,
                  size: 84,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                SizedBox(
                  height: 62,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(yesLabel),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 62,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(noLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeniorHomeContent extends ConsumerWidget {
  const _SeniorHomeContent({
    required this.data,
  });

  final SeniorHomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorId = data.activeSeniorId;
    if (seniorId == null) {
      return EmptyStateBlock(
        title: tr(
          context,
          fr: 'Aucun profil senior actif',
          en: 'No active senior profile',
          ar: 'لا يوجد ملف مسن نشط',
        ),
        description: tr(
          context,
          fr: 'Ouvrez les paramètres pour passer sur un profil senior.',
          en: 'Open settings to switch to a senior profile.',
          ar: 'افتح الإعدادات للتبديل إلى ملف مسن.',
        ),
        icon: Icons.person_off_outlined,
      );
    }

    final profileName = data.profile?.displayName ?? 'there';
    final greeting = switch (Localizations.localeOf(context).languageCode) {
      'ar' => 'مرحبا، $profileName',
      'en' => 'Hello, $profileName',
      _ => 'Bonjour, $profileName',
    };
    final connectivityState =
        ref.watch(connectivityStateProvider).valueOrNull ??
            AppConnectivityState.online;

    return ListView(
      children: [
        Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          tr(
            context,
            fr: 'Les actions rapides ci-dessous informent votre famille.',
            en: 'Quick actions below keep your family informed.',
            ar: 'الإجراءات السريعة أدناه تُبقي عائلتك على اطلاع.',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (connectivityState != AppConnectivityState.online) ...[
          const SizedBox(height: AppSpacing.md),
          ConnectivityBanner(state: connectivityState),
        ],
        const SizedBox(height: AppSpacing.md),
        _StatusCard(summary: data.summary),
        const SizedBox(height: AppSpacing.md),
        if (data.settings.checkInModuleEnabled ||
            data.settings.companionModuleEnabled ||
            data.settings.incidentModuleEnabled) ...[
          _PrimaryActionCard(
            checkInState: data.checkInState,
            checkInEnabled: data.settings.checkInModuleEnabled,
            incidentEnabled: data.settings.incidentModuleEnabled,
            companionEnabled: data.settings.companionModuleEnabled,
            onPrimaryAction: () async {
              final created = await ref
                  .read(checkInRepositoryProvider)
                  .markCheckInCompleted(seniorId);
              ref.invalidate(seniorHomeDataProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    created
                        ? tr(
                            context,
                            fr: 'Check-in confirmé',
                            en: 'Check-in completed',
                            ar: 'تم تأكيد تسجيل الحضور',
                          )
                        : tr(
                            context,
                            fr: 'Déjà confirmé',
                            en: 'Already completed',
                            ar: 'تم التأكيد مسبقًا',
                          ),
                  ),
                ),
              );
            },
            onHelpAction: () async {
              await ref.read(checkInRepositoryProvider).markNeedHelp(seniorId);
              ref.invalidate(seniorHomeDataProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tr(
                      context,
                      fr: 'Demande d’aide envoyée',
                      en: 'Help request sent',
                      ar: 'تم إرسال طلب المساعدة',
                    ),
                  ),
                ),
              );
            },
            onCompanion: () => context.push(AppRoutes.seniorCompanion),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (data.settings.medicationModuleEnabled)
          _MedicationQuickCard(
            reminder: data.nextReminder,
            onTaken: data.nextReminder == null
                ? null
                : () async {
                    await ref
                        .read(medicationRepositoryProvider)
                        .markMedicationTaken(
                          seniorId,
                          planId: data.nextReminder!.plan.id,
                        );
                    ref.invalidate(seniorHomeDataProvider);
                  },
            onMissed: data.nextReminder == null
                ? null
                : () async {
                    await ref
                        .read(medicationRepositoryProvider)
                        .markMedicationMissed(
                          seniorId,
                          planId: data.nextReminder!.plan.id,
                        );
                    ref.invalidate(seniorHomeDataProvider);
                  },
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(status: summary.globalStatus),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary.globalStatus.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.checkInState,
    required this.checkInEnabled,
    required this.incidentEnabled,
    required this.companionEnabled,
    required this.onPrimaryAction,
    required this.onHelpAction,
    required this.onCompanion,
  });

  final CheckInState checkInState;
  final bool checkInEnabled;
  final bool incidentEnabled;
  final bool companionEnabled;
  final VoidCallback onPrimaryAction;
  final VoidCallback onHelpAction;
  final VoidCallback onCompanion;

  @override
  Widget build(BuildContext context) {
    final subtitle = !checkInEnabled
        ? tr(
            context,
            fr: 'Choisissez une action ci-dessous.',
            en: 'Choose an action below.',
            ar: 'اختر إجراءً أدناه.',
          )
        : switch (checkInState.status) {
      CheckInStatus.completed => tr(
          context,
          fr: 'Vous avez déjà confirmé aujourd’hui.',
          en: 'You already checked in today.',
          ar: 'لقد أكدت حضورك اليوم بالفعل.',
        ),
      CheckInStatus.missed => tr(
          context,
          fr: 'Veuillez confirmer maintenant.',
          en: 'Please confirm now.',
          ar: 'يرجى التأكيد الآن.',
        ),
      CheckInStatus.pending => tr(
          context,
          fr: 'Veuillez confirmer maintenant.',
          en: 'Please confirm now.',
          ar: 'يرجى التأكيد الآن.',
        ),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (checkInEnabled) ...[
          BigAction(
            label:
                tr(context, fr: 'Je vais bien', en: 'I\'m okay', ar: 'أنا بخير'),
            subtitle: tr(
              context,
              fr: 'Envoyer le check-in du jour',
              en: 'Send today\'s check-in',
              ar: 'أرسل تأكيد اليوم',
            ),
            icon: Icons.favorite_outline,
            onTap: onPrimaryAction,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (incidentEnabled)
            BigAction(
              label: tr(
                context,
                fr: 'J’ai besoin d’aide',
                en: 'I need help',
                ar: 'أحتاج مساعدة',
              ),
              subtitle: tr(
                context,
                fr: 'Alerter votre famille maintenant',
                en: 'Alert your family now',
                ar: 'نبه عائلتك الآن',
              ),
              icon: Icons.call_outlined,
              tone: BigActionTone.destructive,
              onTap: onHelpAction,
            ),
        ],
        if (companionEnabled) ...[
          const SizedBox(height: AppSpacing.sm),
          BigAction(
            label: tr(
              context,
              fr: 'Parler au Companion',
              en: 'Talk to Companion',
              ar: 'تحدث مع المرافق',
            ),
            subtitle:
                tr(context, fr: 'Par voix', en: 'Ask by voice', ar: 'بالصوت'),
            icon: Icons.mic_outlined,
            tone: BigActionTone.soft,
            onTap: onCompanion,
          ),
        ],
      ],
    );
  }
}

enum _IncidentPromptResult {
  ok,
  help,
  timeout,
}

class IncidentCountdownDialog extends StatefulWidget {
  const IncidentCountdownDialog({
    super.key,
    required this.title,
    required this.message,
    required this.okLabel,
    required this.helpLabel,
    this.initialSeconds = 60,
  });

  final String title;
  final String message;
  final String okLabel;
  final String helpLabel;
  final int initialSeconds;

  @override
  State<IncidentCountdownDialog> createState() => _IncidentCountdownDialogState();
}

class _IncidentCountdownDialogState extends State<IncidentCountdownDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        Navigator.of(context).pop(_IncidentPromptResult.timeout);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.health_and_safety_outlined,
                size: 84,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$_remainingSeconds s',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Spacer(),
              SizedBox(
                height: 62,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_IncidentPromptResult.ok),
                  child: Text(widget.okLabel),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 62,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(_IncidentPromptResult.help),
                  child: Text(widget.helpLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationQuickCard extends StatelessWidget {
  const _MedicationQuickCard({
    required this.reminder,
    required this.onTaken,
    required this.onMissed,
  });

  final MedicationReminder? reminder;
  final VoidCallback? onTaken;
  final VoidCallback? onMissed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.sage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, fr: 'Médicament', en: 'Medication', ar: 'الدواء'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reminder == null
                ? tr(
                    context,
                    fr: 'Prochain médicament : aucun rappel en attente.',
                    en: 'Next medication: no pending reminder.',
                    ar: 'الدواء التالي: لا يوجد تذكير معلق.',
                  )
                : tr(
                    context,
                    fr:
                        'Prochain médicament : ${reminder!.plan.medicationName} à ${reminder!.slotLabel}.',
                    en:
                        'Next medication: ${reminder!.plan.medicationName} at ${reminder!.slotLabel}.',
                    ar:
                        'الدواء التالي: ${reminder!.plan.medicationName} عند ${reminder!.slotLabel}.',
                  ),
          ),
          if (reminder != null &&
              reminder!.status == MedicationReminderStatus.pending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onTaken,
                    child: Text(
                      tr(context, fr: 'Pris', en: 'Taken', ar: 'تم'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMissed,
                    child: Text(
                      tr(
                        context,
                        fr: 'Pas encore',
                        en: 'Not yet',
                        ar: 'ليس بعد',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
