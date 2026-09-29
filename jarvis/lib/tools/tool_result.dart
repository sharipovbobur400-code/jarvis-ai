/// Universal result format returned by every tool (section 28 of the spec).
class ToolResult {
  final bool success;
  final String tool;
  final String? message;
  final String? error;
  final Map<String, dynamic> data;

  const ToolResult({
    required this.success,
    required this.tool,
    this.message,
    this.error,
    this.data = const {},
  });

  factory ToolResult.ok(String tool, String message,
          [Map<String, dynamic> data = const {}]) =>
      ToolResult(success: true, tool: tool, message: message, data: data);

  factory ToolResult.fail(String tool, String error) =>
      ToolResult(success: false, tool: tool, error: error);

  Map<String, dynamic> toJson() => {
        'success': success,
        'tool': tool,
        if (message != null) 'message': message,
        if (error != null) 'error': error,
        ...data,
      };
}
