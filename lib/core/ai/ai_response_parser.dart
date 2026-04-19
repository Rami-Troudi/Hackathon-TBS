import 'package:senior_companion/core/ai/ai_response.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';

class AiResponseParser {
  const AiResponseParser();

  AiResponse parseExternalText(
    String? raw, {
    required List<String> referencedFacts,
    required List<AssistantSuggestion> suggestions,
  }) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) {
      return AiResponse(
        answerText:
            'I could not generate an external answer right now, so I am using local guidance.',
        source: AiResponseSource.fallback,
        referencedFacts: referencedFacts,
        suggestions: suggestions,
      );
    }

    return AiResponse(
      answerText: text,
      source: AiResponseSource.external,
      referencedFacts: referencedFacts,
      suggestions: suggestions,
    );
  }
}
