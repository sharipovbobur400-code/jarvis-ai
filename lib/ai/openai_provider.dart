import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider.dart';
import '../tools/tool_registry.dart';
import '../core/utils/logger.dart';

class OpenAIProvider implements BaseAIProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  OpenAIProvider({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
        ));

  @override
  String get name => 'OpenAI ($model)';

  @override
  Future<AIResponse> sendMessage({
    required String prompt,
    required String systemPrompt,
    List<Map<String, dynamic>> conversationHistory = const [],
    bool enableTools = true,
  }) async {
    if (apiKey.isEmpty) {
      return AIResponse.error('OpenAI API key is not configured.');
    }

    const url = 'https://api.openai.com/v1/chat/completions';

    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        ...conversationHistory,
        {'role': 'user', 'content': prompt},
      ];

      final Map<String, dynamic> body = {
        'model': model,
        'messages': messages,
        'temperature': 0.3,
      };

      if (enableTools) {
        body['tools'] = ToolRegistry().getOpenAiToolsDeclaration();
      }

      final response = await _dio.post(url, data: jsonEncode(body));

      if (response.statusCode == 200 && response.data != null) {
        final choice = response.data['choices'][0]['message'];
        final content = choice['content'] as String? ?? '';
        final toolCallsList = <AIToolCall>[];

        if (choice.containsKey('tool_calls') && choice['tool_calls'] != null) {
          for (var t in (choice['tool_calls'] as List)) {
            final f = t['function'];
            final args = jsonDecode(f['arguments'] as String);
            toolCallsList.add(AIToolCall(
              id: t['id'] ?? '',
              name: f['name'] ?? '',
              arguments: args,
            ));
          }
        }

        return AIResponse(
          text: content.trim(),
          toolCalls: toolCallsList,
          rawResponse: jsonEncode(response.data),
        );
      } else {
        return AIResponse.error('OpenAI Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      JarvisLogger.error('OpenAI request failed', e);
      return AIResponse.error('OpenAI API Error: ${e.response?.data?['error']?['message'] ?? e.message}');
    } catch (e) {
      return AIResponse.error('OpenAI Error: $e');
    }
  }
}
