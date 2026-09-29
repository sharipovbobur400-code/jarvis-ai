import 'base_tool.dart';
import 'application_tool.dart';
import 'browser_tool.dart';
import 'media_tool.dart';
import 'file_tool.dart';
import 'terminal_tool.dart';
import 'code_generator_tool.dart';
import 'system_tool.dart';

class ToolRegistry {
  static final ToolRegistry _instance = ToolRegistry._internal();
  factory ToolRegistry() => _instance;
  ToolRegistry._internal() {
    _registerDefaultTools();
  }

  final Map<String, BaseJarvisTool> _tools = {};

  void _registerDefaultTools() {
    register(ApplicationTool());
    register(BrowserTool());
    register(MediaTool());
    register(FileTool());
    register(TerminalTool());
    register(CodeGeneratorTool());
    register(SystemTool());
  }

  void register(BaseJarvisTool tool) {
    _tools[tool.name] = tool;
  }

  BaseJarvisTool? getTool(String name) => _tools[name];

  List<BaseJarvisTool> getAllTools() => _tools.values.toList();

  List<Map<String, dynamic>> getGeminiToolsDeclaration() {
    return [
      {
        'function_declarations': _tools.values.map((tool) {
          return {
            'name': tool.name,
            'description': tool.description,
            'parameters': tool.parametersSchema,
          };
        }).toList()
      }
    ];
  }

  List<Map<String, dynamic>> getOpenAiToolsDeclaration() {
    return _tools.values.map((tool) {
      return {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.parametersSchema,
        }
      };
    }).toList();
  }

  Future<ToolResult> execute(String name, Map<String, dynamic> arguments) async {
    final tool = _tools[name];
    if (tool == null) {
      return ToolResult.failure(tool: name, error: 'Tool "$name" not found in registry.');
    }
    return await tool.execute(arguments);
  }
}
