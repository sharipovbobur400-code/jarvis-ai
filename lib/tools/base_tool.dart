class ToolResult {
  final bool success;
  final String tool;
  final String message;
  final dynamic data;
  final String? error;

  ToolResult({
    required this.success,
    required this.tool,
    required this.message,
    this.data,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'tool': tool,
    'message': message,
    if (data != null) 'data': data,
    if (error != null) 'error': error,
  };

  factory ToolResult.success({
    required String tool,
    required String message,
    dynamic data,
  }) {
    return ToolResult(
      success: true,
      tool: tool,
      message: message,
      data: data,
    );
  }

  factory ToolResult.failure({
    required String tool,
    required String error,
    dynamic data,
  }) {
    return ToolResult(
      success: false,
      tool: tool,
      message: error,
      error: error,
      data: data,
    );
  }
}

abstract class BaseJarvisTool {
  String get name;
  String get description;
  Map<String, dynamic> get parametersSchema;

  Future<ToolResult> execute(Map<String, dynamic> arguments);
}
