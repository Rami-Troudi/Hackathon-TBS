import 'package:senior_companion/shared/models/assistant_message.dart';

enum AssistantAudience {
  senior,
  guardian,
}

class AiRequest {
  const AiRequest({
    required this.audience,
    required this.userMessage,
    required this.history,
    required this.requestedAt,
  });

  final AssistantAudience audience;
  final String userMessage;
  final List<AssistantMessage> history;
  final DateTime requestedAt;
}
