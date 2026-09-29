import 'package:dio/dio.dart';
import 'ai_provider.dart';

/// Google Gemini provider (free tier friendly, good multilingual support).
class GeminiProvider implements AiProvider {
  final String apiKey;
  final String model;
  final Dio _dio = Dio();

  GeminiProvider({required this.apiKey, this.model = 'gemini-1.5-flash'});

  @override
  String get name => 'Gemini';

  @override
  Future<String> chat(List<Map<String, String>> messages) =>
      _send(messages, null);

  @override
  Future<String> chatWithTools(
          List<Map<String, String>> messages, String toolCatalog) =>
      _send(messages, toolCatalog);

  Future<String> _send(
      List<Map<String, String>> messages, String? toolCatalog) async {
    final system = messages
        .where((m) => m['role'] == 'system')
        .map((m) => m['content'])
        .join('\n\n');
    final contents = messages
        .where((m) => m['role'] != 'system')
        .map((m) => {
              'role': m['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m['content'] ?? ''}
              ],
            })
        .toList();

    if (toolCatalog != null && toolCatalog.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': toolCatalog}
        ],
      });
    }

    try {
      final res = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent?key=$apiKey',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': contents,
          if (system != null && system.isNotEmpty)
            'systemInstruction': {
              'parts': [
                {'text': system}
              ]
            },
          'generationConfig': {'temperature': 0.6, 'maxOutputTokens': 2048},
        },
      );
      final candidates = res.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw AiException("AI javob qaytarmadi.");
      }
      final parts = candidates[0]['content']['parts'] as List;
      return parts.map((p) => p['text'] ?? '').join();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error']?['message'] ?? e.message)
          : e.message;
      throw AiException("AI xizmatiga ulanolmadi: $msg");
    }
  }
}
