class AIResponse {
  final String text;
  final List<AIToolCall> toolCalls;
  final String? rawResponse;
  final bool isError;
  final String? errorMessage;

  AIResponse({
    required this.text,
    this.toolCalls = const [],
    this.rawResponse,
    this.isError = false,
    this.errorMessage,
  });

  factory AIResponse.error(String message) => AIResponse(
    text: message,
    isError: true,
    errorMessage: message,
  );
}

class AIToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  AIToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'arguments': arguments,
  };
}

abstract class BaseAIProvider {
  String get name;
  Future<AIResponse> sendMessage({
    required String prompt,
    required String systemPrompt,
    List<Map<String, dynamic>> conversationHistory = const [],
    bool enableTools = true,
  });
}
