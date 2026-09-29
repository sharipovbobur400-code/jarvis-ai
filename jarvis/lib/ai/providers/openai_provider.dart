import 'package:dio/dio.dart';
import 'ai_provider.dart';

/// OpenAI ChatGPT provider.
class OpenAiProvider implements AiProvider {
  final String apiKey;
  final String model;
  final Dio _dio = Dio();

  OpenAiProvider({required this.apiKey, this.model = 'gpt-4o-mini'});

  @override
  String get name => 'OpenAI';

  @override
  Future<String> chat(List<Map<String, String>> messages) =>
      _send(messages, null);

  @override
  Future<String> chatWithTools(
          List<Map<String, String>> messages, String toolCatalog) =>
      _send(messages, toolCatalog);

  Future<String> _send(
      List<Map<String, String>> messages, String? toolCatalog) async {
    final all = List<Map<String, String>>.from(messages);
    if (toolCatalog != null && toolCatalog.isNotEmpty) {
      all.add({'role': 'system', 'content': toolCatalog});
    }
    try {
      final res = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
        data: {
          'model': model,
          'messages': all,
          'temperature': 0.6,
        },
      );
      return res.data['choices'][0]['message']['content'] as String? ?? '';
    } on DioException catch (e) {
      throw AiException("AI xizmatiga ulanolmadi: ${e.message}");
    }
  }
}
