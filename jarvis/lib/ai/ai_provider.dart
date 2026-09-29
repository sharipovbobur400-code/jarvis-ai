/// Pluggable AI provider interface (section 4).
/// Implementations: GeminiProvider, OpenAIProvider, LocalAIProvider.
abstract class AiProvider {
  String get name;

  /// Sends the conversation and returns the assistant's reply text.
  /// [messages] entries: {'role': 'user'|'assistant'|'system', 'content': '...'}
  Future<String> chat(List<Map<String, String>> messages);

  /// Ask the model to pick and parameterize a tool, given a tool catalog.
  /// Returns raw model output; the caller parses it.
  Future<String> chatWithTools(
      List<Map<String, String>> messages, String toolCatalog);
}

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}
