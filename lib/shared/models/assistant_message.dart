import 'package:senior_companion/shared/models/assistant_role.dart';
import 'package:senior_companion/shared/models/assistant_suggestion.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.referencedFacts = const <String>[],
    this.suggestions = const <AssistantSuggestion>[],
  });

  final String id;
  final AssistantRole role;
  final String text;
  final DateTime createdAt;
  final List<String> referencedFacts;
  final List<AssistantSuggestion> suggestions;

  AssistantMessage copyWith({
    String? id,
    AssistantRole? role,
    String? text,
    DateTime? createdAt,
    List<String>? referencedFacts,
    List<AssistantSuggestion>? suggestions,
  }) {
    return AssistantMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      referencedFacts: referencedFacts ?? this.referencedFacts,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
