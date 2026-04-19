import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/ai/ai_assistant_repository.dart';
import 'package:senior_companion/core/ai/ai_response.dart';
import 'package:senior_companion/features/companion/guardian_insights_providers.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';

class _FakeAiAssistantRepository implements AiAssistantRepository {
  int guardianAskCalls = 0;

  @override
  Future<AiResponse> askGuardian(
    String userMessage, {
    List<AssistantMessage> history = const <AssistantMessage>[],
  }) async {
    guardianAskCalls += 1;
    return AiResponse(
      answerText: 'Guardian fallback answer for: $userMessage',
      source: AiResponseSource.fallback,
      referencedFacts: const <String>['Active alerts: 2'],
      suggestions: const <AssistantSuggestion>[
        AssistantSuggestion(
          label: 'Explain active alerts',
          prompt: 'Explain active alerts.',
        ),
      ],
    );
  }

  @override
  Future<AiResponse> askSenior(
    String userMessage, {
    List<AssistantMessage> history = const <AssistantMessage>[],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AiResponse> buildGuardianWelcome() async => const AiResponse(
        answerText: 'Welcome guardian insights',
        source: AiResponseSource.fallback,
        suggestions: <AssistantSuggestion>[
          AssistantSuggestion(
            label: 'What changed today?',
            prompt: 'What changed today?',
          ),
        ],
      );

  @override
  Future<AiResponse> buildSeniorWelcome() {
    throw UnimplementedError();
  }
}

void main() {
  test('guardian insights provider initializes and answers user question',
      () async {
    final fakeRepository = _FakeAiAssistantRepository();
    final container = ProviderContainer(
      overrides: [
        aiAssistantRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier =
        container.read(guardianInsightsControllerProvider.notifier);
    await notifier.ensureInitialized();
    await notifier.sendText('What changed today?');

    final state = container.read(guardianInsightsControllerProvider);
    expect(state.messages.length, 3);
    expect(state.messages.first.text, contains('Welcome guardian insights'));
    expect(state.messages.last.text, contains('Guardian fallback answer'));
    expect(fakeRepository.guardianAskCalls, 1);
  });
}
