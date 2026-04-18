import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/daily_summary.dart';
import 'package:senior_companion/shared/models/senior_profile.dart';

class SeniorSummaryData {
  const SeniorSummaryData({
    required this.seniorId,
    required this.summary,
  });

  final String? seniorId;
  final DailySummary summary;
}

final seniorSummaryDataProvider =
    FutureProvider.autoDispose<SeniorSummaryData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final summaryRepository = ref.watch(summaryRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return SeniorSummaryData(
      seniorId: null,
      summary: DailySummary(
        audience: DailySummaryAudience.senior,
        generatedAt: DateTime.now().toUtc(),
        headline: 'No active profile selected.',
        whatWentWell: const <String>[],
        needsAttention: const <String>[],
        notableEvents: const <String>[],
      ),
    );
  }

  final summary = await summaryRepository.buildSeniorDailySummary(seniorId);
  return SeniorSummaryData(seniorId: seniorId, summary: summary);
});

class GuardianSummaryData {
  const GuardianSummaryData({
    required this.seniorId,
    required this.seniorProfile,
    required this.summary,
  });

  final String? seniorId;
  final SeniorProfile? seniorProfile;
  final DailySummary summary;
}

final guardianSummaryDataProvider =
    FutureProvider.autoDispose<GuardianSummaryData>((ref) async {
  final resolver = ref.watch(activeSeniorResolverProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final summaryRepository = ref.watch(summaryRepositoryProvider);
  final seniorId = await resolver.resolveActiveSeniorId();
  if (seniorId == null) {
    return GuardianSummaryData(
      seniorId: null,
      seniorProfile: null,
      summary: DailySummary(
        audience: DailySummaryAudience.guardian,
        generatedAt: DateTime.now().toUtc(),
        headline: 'No linked senior selected.',
        whatWentWell: const <String>[],
        needsAttention: const <String>[],
        notableEvents: const <String>[],
      ),
    );
  }

  final profile = await profileRepository.getSeniorProfileById(seniorId);
  final summary = await summaryRepository.buildGuardianDailySummary(seniorId);
  return GuardianSummaryData(
    seniorId: seniorId,
    seniorProfile: profile,
    summary: summary,
  );
});
