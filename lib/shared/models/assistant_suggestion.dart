class AssistantSuggestion {
  const AssistantSuggestion({
    required this.label,
    required this.prompt,
    this.routeHint,
  });

  final String label;
  final String prompt;
  final String? routeHint;
}
