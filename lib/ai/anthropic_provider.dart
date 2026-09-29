import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider.dart';
import '../tools/tool_registry.dart';
import '../core/utils/logger.dart';

class AnthropicProvider implements BaseAIProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  AnthropicProvider({
    required this.apiKey,
    this.model = 'claude-3-5-sonnet-20241022',
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        ));

  @override
  String get name => 'Anthropic Claude ($model)';

  @override
  Future<AIResponse> sendMessage({
    required String prompt,
    required String systemPrompt,
    List<Map<String, dynamic>> conversationHistory = const [],
    bool enableTools = true,
  }) async {
    if (apiKey.isEmpty) {
      return AIResponse.error('Anthropic API key is not configured.');
    }

    const url = 'https://api.anthropic.com/v1/messages';

    try {
      final messages = <Map<String, dynamic>>[];
      for (var item in conversationHistory) {
        messages.add({
          'role': item['role'] == 'user' ? 'user' : 'assistant',
          'content': item['content'] ?? '',
        });
      }
      messages.add({'role': 'user', 'content': prompt});

      final Map<String, dynamic> body = {
        'model': model,
        'max_tokens': 2048,
        'system': systemPrompt,
        'messages': messages,
      };

      if (enableTools) {
        body['tools'] = ToolRegistry().getAllTools().map((t) => {
          'name': t.name,
          'description': t.description,
          'input_schema': t.parametersSchema,
        }).toList();
      }

      final response = await _dio.post(url, data: jsonEncode(body));

      if (response.statusCode == 200 && response.data != null) {
        final contentList = response.data['content'] as List;
        String text = '';
        final toolCalls = <AIToolCall>[];

        for (var c in contentList) {
          if (c['type'] == 'text') {
            text += c['text'] ?? '';
          } else if (c['type'] == 'tool_use') {
            toolCalls.add(AIToolCall(
              id: c['id'] ?? '',
              name: c['name'] ?? '',
              arguments: c['input'] as Map<String, dynamic>? ?? {},
            ));
          }
        }

        return AIResponse(
          text: text.trim(),
          toolCalls: toolCalls,
          rawResponse: jsonEncode(response.data),
        );
      } else {
        return AIResponse.error('Claude API Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      JarvisLogger.error('Claude request failed', e);
      return AIResponse.error('Claude API Error: ${e.response?.data?['error']?['message'] ?? e.message}');
    } catch (e) {
      return AIResponse.error('Claude Error: $e');
    }
  }
}
