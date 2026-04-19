import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senior_companion/app/bootstrap/providers.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';
import 'package:senior_companion/shared/models/assistant_role.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';

class GuardianInsightsState {
  const GuardianInsightsState({
    required this.messages,
    required this.suggestions,
    required this.isSending,
    required this.hasInitialized,
  });

  final List<AssistantMessage> messages;
  final List<AssistantSuggestion> suggestions;
  final bool isSending;
  final bool hasInitialized;

  GuardianInsightsState copyWith({
    List<AssistantMessage>? messages,
    List<AssistantSuggestion>? suggestions,
    bool? isSending,
    bool? hasInitialized,
  }) {
    return GuardianInsightsState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isSending: isSending ?? this.isSending,
      hasInitialized: hasInitialized ?? this.hasInitialized,
    );
  }

  factory GuardianInsightsState.initial({
    required List<AssistantSuggestion> suggestions,
  }) {
    return GuardianInsightsState(
      messages: const <AssistantMessage>[],
      suggestions: suggestions,
      isSending: false,
      hasInitialized: false,
    );
  }
}

class GuardianInsightsController extends StateNotifier<GuardianInsightsState> {
  GuardianInsightsController({
    required this.ref,
  }) : super(
          GuardianInsightsState.initial(
            suggestions:
                ref.read(aiFallbackServiceProvider).guardianSuggestions(),
          ),
        );

  final Ref ref;

  Future<void> ensureInitialized() async {
    if (state.hasInitialized) return;
    state = state.copyWith(hasInitialized: true);
    final welcome =
        await ref.read(aiAssistantRepositoryProvider).buildGuardianWelcome();
    final message = AssistantMessage(
      id: _nextId('assistant'),
      role: AssistantRole.assistant,
      text: welcome.answerText,
      createdAt: DateTime.now().toUtc(),
      referencedFacts: welcome.referencedFacts,
      suggestions: welcome.suggestions,
    );
    state = state.copyWith(messages: <AssistantMessage>[message]);
  }

  Future<void> sendText(String input) async {
    final text = input.trim();
    if (text.isEmpty || state.isSending) return;
    final userMessage = AssistantMessage(
      id: _nextId('user'),
      role: AssistantRole.user,
      text: text,
      createdAt: DateTime.now().toUtc(),
    );
    final updatedMessages = <AssistantMessage>[...state.messages, userMessage];
    state = state.copyWith(messages: updatedMessages, isSending: true);

    final response = await ref.read(aiAssistantRepositoryProvider).askGuardian(
          text,
          history: updatedMessages,
        );
    final assistantMessage = AssistantMessage(
      id: _nextId('assistant'),
      role: AssistantRole.assistant,
      text: response.answerText,
      createdAt: DateTime.now().toUtc(),
      referencedFacts: response.referencedFacts,
      suggestions: response.suggestions,
    );
    state = state.copyWith(
      messages: <AssistantMessage>[...updatedMessages, assistantMessage],
      suggestions: response.suggestions,
      isSending: false,
    );
  }

  Future<void> sendSuggestion(AssistantSuggestion suggestion) async {
    await sendText(suggestion.prompt);
  }

  String _nextId(String prefix) {
    return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }
}

final guardianInsightsControllerProvider = StateNotifierProvider.autoDispose<
    GuardianInsightsController, GuardianInsightsState>(
  (ref) => GuardianInsightsController(ref: ref),
);
