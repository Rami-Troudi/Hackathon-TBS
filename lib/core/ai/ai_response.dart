import 'package:senior_companion/shared/models/assistant_suggestion.dart';

enum AiResponseSource {
  fallback,
  external,
}

class AiResponse {
  const AiResponse({
    required this.answerText,
    required this.source,
    this.referencedFacts = const <String>[],
    this.suggestions = const <AssistantSuggestion>[],
  });

  final String answerText;
  final AiResponseSource source;
  final List<String> referencedFacts;
  final List<AssistantSuggestion> suggestions;

  AiResponse copyWith({
    String? answerText,
    AiResponseSource? source,
    List<String>? referencedFacts,
    List<AssistantSuggestion>? suggestions,
  }) {
    return AiResponse(
      answerText: answerText ?? this.answerText,
      source: source ?? this.source,
      referencedFacts: referencedFacts ?? this.referencedFacts,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
