import 'dart:async';
import 'package:uuid/uuid.dart';
import 'ai_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';
import 'anthropic_provider.dart';
import 'local_ai_provider.dart';
import 'prompt_manager.dart';
import 'memory_manager.dart';
import 'task_planner.dart';
import '../tools/tool_registry.dart';
import '../core/config/app_config.dart';
import '../core/storage/local_database.dart';
import '../core/utils/logger.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final LocalDatabaseService _db = LocalDatabaseService();
  final MemoryManager _memoryManager = MemoryManager();
  final TaskPlanner _taskPlanner = TaskPlanner();

  BaseAIProvider _getProvider() {
    final config = AppConfig();
    switch (config.currentProvider) {
      case AIProviderType.gemini:
        return GeminiProvider(apiKey: config.geminiApiKey ?? '');
      case AIProviderType.openai:
        return OpenAIProvider(apiKey: config.openaiApiKey ?? '');
      case AIProviderType.anthropic:
        return AnthropicProvider(apiKey: config.anthropicApiKey ?? '');
      case AIProviderType.local:
        return LocalAIProvider(serverUrl: config.localAiUrl);
    }
  }

  Future<String> processUserCommand(
    String userText, {
    Function(String statusMessage)? onStatusUpdate,
    Function(JarvisPlan plan)? onPlanUpdate,
  }) async {
    if (userText.trim().isEmpty) return '';

    // 1. Log & Store User message
    final userMsgId = const Uuid().v4();
    await _db.addMessage(ConversationMessage(
      id: userMsgId,
      role: 'user',
      content: userText,
      timestamp: DateTime.now(),
    ));

    // 2. Extract potential user memories (e.g. name, language)
    await _memoryManager.processUserMessageForMemories(userText);

    // 3. Check if this is a complex multi-step request
    final plan = _taskPlanner.createPlanFromIntent(userText);
    if (plan.steps.isNotEmpty) {
      onPlanUpdate?.call(plan);
      onStatusUpdate?.call('Vazifa rejalashtirildi: ${plan.steps.length} bosqich.');

      final success = await _taskPlanner.executePlan(plan, onStepUpdate: (step) {
        onStatusUpdate?.call('${step.title}...');
      });

      String finalSpeech = '';
      if (success) {
        finalSpeech = '${plan.taskTitle} muvaffaqiyatli yakunlandi.';
      } else {
        finalSpeech = 'Vazifani bajarishda xatolik yuz berdi.';
      }

      await _db.addMessage(ConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: finalSpeech,
        timestamp: DateTime.now(),
      ));

      return finalSpeech;
    }

    // 4. Send to active AI Provider with system prompt & tool declarations
    final provider = _getProvider();
    final systemPrompt = PromptManager.buildSystemPrompt();
    final history = _db.getRecentMessages(6).map((m) => {
      'role': m.role,
      'content': m.content,
    }).toList();

    onStatusUpdate?.call('Fikrlayapman...');
    AIResponse response = await provider.sendMessage(
      prompt: userText,
      systemPrompt: systemPrompt,
      conversationHistory: history,
      enableTools: true,
    );

    // Fallback to local heuristic provider if API key is invalid or offline
    if (response.isError) {
      JarvisLogger.warn('Primary AI failed, falling back to Local Heuristic Provider: ${response.errorMessage}');
      onStatusUpdate?.call('Lokal AI ishga tushmoqda...');
      final localProvider = LocalAIProvider();
      response = await localProvider.sendMessage(
        prompt: userText,
        systemPrompt: systemPrompt,
        conversationHistory: history,
        enableTools: true,
      );
    }

    // 5. Execute any requested tool calls
    String toolResultsSummary = '';
    if (response.toolCalls.isNotEmpty) {
      for (var toolCall in response.toolCalls) {
        onStatusUpdate?.call('${toolCall.name} bajarilmoqda...');
        JarvisLogger.tool(toolCall.name, 'Executing with arguments: ${toolCall.arguments}');

        final result = await ToolRegistry().execute(toolCall.name, toolCall.arguments);
        if (result.success) {
          toolResultsSummary += '${result.message} ';
        } else {
          toolResultsSummary += 'Xatolik: ${result.error}. ';
        }
      }
    }

    String finalOutput = response.text;
    if (toolResultsSummary.isNotEmpty) {
      if (finalOutput.isEmpty) {
        finalOutput = toolResultsSummary.trim();
      } else {
        finalOutput = '$finalOutput ($toolResultsSummary)'.trim();
      }
    }

    if (finalOutput.isEmpty) {
      finalOutput = 'Buyruq bajarildi.';
    }

    // 6. Save assistant response
    await _db.addMessage(ConversationMessage(
      id: const Uuid().v4(),
      role: 'assistant',
      content: finalOutput,
      timestamp: DateTime.now(),
    ));

    return finalOutput;
  }
}
