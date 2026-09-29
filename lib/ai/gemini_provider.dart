import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider.dart';
import '../tools/tool_registry.dart';
import '../core/utils/logger.dart';

class GeminiProvider implements BaseAIProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  GeminiProvider({
    required this.apiKey,
    this.model = 'gemini-1.5-flash',
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  @override
  String get name => 'Google Gemini ($model)';

  @override
  Future<AIResponse> sendMessage({
    required String prompt,
    required String systemPrompt,
    List<Map<String, dynamic>> conversationHistory = const [],
    bool enableTools = true,
  }) async {
    if (apiKey.isEmpty) {
      return AIResponse.error('Gemini API key is not configured. Please set your API key in Settings.');
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    try {
      // Build contents list
      final contents = <Map<String, dynamic>>[];

      for (var item in conversationHistory) {
        final role = item['role'] == 'user' ? 'user' : 'model';
        contents.add({
          'role': role,
          'parts': [{'text': item['content'] ?? ''}],
        });
      }

      contents.add({
        'role': 'user',
        'parts': [{'text': prompt}],
      });

      final Map<String, dynamic> requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [{'text': systemPrompt}]
        },
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2048,
        },
      };

      if (enableTools) {
        final toolDeclarations = ToolRegistry().getGeminiToolsDeclaration();
        requestBody['tools'] = toolDeclarations;
      }

      JarvisLogger.info('Sending request to Gemini: $model');

      final response = await _dio.post(url, data: jsonEncode(requestBody));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          return AIResponse(text: 'Kechirasiz, javob ololmadim.');
        }

        final content = candidates[0]['content'];
        final parts = content['parts'] as List? ?? [];

        String responseText = '';
        final toolCalls = <AIToolCall>[];

        for (var part in parts) {
          if (part.containsKey('text')) {
            responseText += part['text'] as String;
          }
          if (part.containsKey('functionCall')) {
            final funcCall = part['functionCall'] as Map<String, dynamic>;
            final funcName = funcCall['name'] as String;
            final args = (funcCall['args'] as Map<String, dynamic>?) ?? {};

            toolCalls.add(AIToolCall(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: funcName,
              arguments: args,
            ));
          }
        }

        return AIResponse(
          text: responseText.trim(),
          toolCalls: toolCalls,
          rawResponse: jsonEncode(data),
        );
      } else {
        return AIResponse.error('Gemini API Error: ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      JarvisLogger.error('Gemini request failed', e);
      final msg = e.response?.data?['error']?['message'] ?? e.message;
      return AIResponse.error('Gemini ulanish xatosi: $msg');
    } catch (e) {
      JarvisLogger.error('Gemini unexpected error', e);
      return AIResponse.error('AI xatosi: $e');
    }
  }
}
