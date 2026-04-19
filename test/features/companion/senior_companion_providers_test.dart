import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/core/ai/ai_assistant_repository.dart';
import 'package:senior_companion/core/ai/ai_response.dart';
import 'package:senior_companion/features/companion/senior_companion_providers.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';

class _FakeAiAssistantRepository implements AiAssistantRepository {
  int seniorAskCalls = 0;

  @override
  Future<AiResponse> askGuardian(
    String userMessage, {
    List<AssistantMessage> history = const <AssistantMessage>[],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AiResponse> askSenior(
    String userMessage, {
    List<AssistantMessage> history = const <AssistantMessage>[],
  }) async {
    seniorAskCalls += 1;
    return AiResponse(
      answerText: 'Senior fallback answer for: $userMessage',
      source: AiResponseSource.fallback,
      referencedFacts: const <String>['Status: Watch'],
      suggestions: const <AssistantSuggestion>[
        AssistantSuggestion(
          label: 'What reminders are left?',
          prompt: 'What reminders are left today?',
        ),
      ],
    );
  }

  @override
  Future<AiResponse> buildGuardianWelcome() {
    throw UnimplementedError();
  }

  @override
  Future<AiResponse> buildSeniorWelcome() async => const AiResponse(
        answerText: 'Welcome senior companion',
        source: AiResponseSource.fallback,
        suggestions: <AssistantSuggestion>[
          AssistantSuggestion(
            label: 'What should I do now?',
            prompt: 'What should I do now?',
          ),
        ],
      );
}

void main() {
  test('senior companion provider initializes and answers user question',
      () async {
    final fakeRepository = _FakeAiAssistantRepository();
    final container = ProviderContainer(
      overrides: [
        aiAssistantRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(seniorCompanionControllerProvider.notifier);
    await notifier.ensureInitialized();
    await notifier.sendText('What should I do now?');

    final state = container.read(seniorCompanionControllerProvider);
    expect(state.messages.length, 3);
    expect(state.messages.first.text, contains('Welcome senior companion'));
    expect(state.messages.last.text, contains('Senior fallback answer'));
    expect(fakeRepository.seniorAskCalls, 1);
  });
}
