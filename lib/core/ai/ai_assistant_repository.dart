import 'package:senior_companion/core/ai/ai_context_builder.dart';
import 'package:senior_companion/core/ai/ai_fallback_service.dart';
import 'package:senior_companion/core/ai/ai_prompt_builder.dart';
import 'package:senior_companion/core/ai/ai_provider_adapter.dart';
import 'package:senior_companion/core/ai/ai_request.dart';
import 'package:senior_companion/core/ai/ai_response.dart';
import 'package:senior_companion/core/ai/ai_response_parser.dart';
import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/shared/models/assistant_message.dart';

abstract class AiAssistantRepository {
  Future<AiResponse> askSenior(
    String userMessage, {
    List<AssistantMessage> history,
  });

  Future<AiResponse> askGuardian(
    String userMessage, {
    List<AssistantMessage> history,
  });

  Future<AiResponse> buildSeniorWelcome();

  Future<AiResponse> buildGuardianWelcome();
}

class LocalAiAssistantRepository implements AiAssistantRepository {
  const LocalAiAssistantRepository({
    required this.contextBuilder,
    required this.promptBuilder,
    required this.providerAdapter,
    required this.responseParser,
    required this.fallbackService,
    required this.logger,
  });

  final AiContextBuilder contextBuilder;
  final AiPromptBuilder promptBuilder;
  final AiProviderAdapter providerAdapter;
  final AiResponseParser responseParser;
  final AiFallbackService fallbackService;
  final AppLogger logger;

  @override
  Future<AiResponse> askSenior(
    String userMessage, {
    List<AssistantMessage> history = const <AssistantMessage>[],
  }) async {
    final context = await contextBuilder.buildSeniorContext();
    final fallback = fallbackService.buildSeniorResponse(
      context: context,
      userMessage: userMessage,
    );
    if (!providerAdapter.isConfigured) {
      return fallback;
    }

    final request = AiRequest(
      audience: AssistantAudience.senior,
      userMessage: userMessage,
      history: history,
      requestedAt: DateTime.now().toUtc(),
    );
    final prompt = promptBuilder.buildSeniorPrompt(
      context: context,
      request: request,
    );

    try {
      final externalText = await providerAdapter.generateText(
        request: request,
        prompt: prompt,
      );
      return responseParser.parseExternalText(
        externalText,
        referencedFacts: fallback.referencedFacts,
        suggestions: fallback.suggestions,
      );
    } catch (error, stackTrace) {
      logger.warn('External senior AI provider failed: $error');
      logger.debug(stackTrace.toString());
      return fallback;
    }
  }

  @override
  Future<AiResponse> askGuardian(
    String userMessage, {
    List<AssistantMessage> history = const <AssistantMessage>[],
  }) async {
    final context = await contextBuilder.buildGuardianContext();
    final fallback = fallbackService.buildGuardianResponse(
      context: context,
      userMessage: userMessage,
    );
    if (!providerAdapter.isConfigured) {
      return fallback;
    }

    final request = AiRequest(
      audience: AssistantAudience.guardian,
      userMessage: userMessage,
      history: history,
      requestedAt: DateTime.now().toUtc(),
    );
    final prompt = promptBuilder.buildGuardianPrompt(
      context: context,
      request: request,
    );

    try {
      final externalText = await providerAdapter.generateText(
        request: request,
        prompt: prompt,
      );
      return responseParser.parseExternalText(
        externalText,
        referencedFacts: fallback.referencedFacts,
        suggestions: fallback.suggestions,
      );
    } catch (error, stackTrace) {
      logger.warn('External guardian AI provider failed: $error');
      logger.debug(stackTrace.toString());
      return fallback;
    }
  }

  @override
  Future<AiResponse> buildSeniorWelcome() async {
    final context = await contextBuilder.buildSeniorContext();
    return fallbackService.buildSeniorSummaryResponse(context);
  }

  @override
  Future<AiResponse> buildGuardianWelcome() async {
    final context = await contextBuilder.buildGuardianContext();
    return fallbackService.buildGuardianSummaryResponse(context);
  }
}
