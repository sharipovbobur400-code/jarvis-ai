import 'dart:io';
import 'package:flutter/foundation.dart';
import 'base_tool.dart';
import '../core/utils/logger.dart';

class ApplicationTool extends BaseJarvisTool {
  @override
  String get name => 'open_application';

  @override
  String get description => 'Opens a desktop application on Windows (e.g. Visual Studio Code, Google Chrome, Telegram, Notepad, Calculator, Explorer).';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'application_name': {
        'type': 'string',
        'description': 'The name or alias of the application to open (e.g., "chrome", "vscode", "notepad", "telegram", "calculator", "explorer")',
      },
      'arguments': {
        'type': 'string',
        'description': 'Optional arguments to pass to the executable',
      },
    },
    'required': ['application_name'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final appName = arguments['application_name']?.toString().toLowerCase().trim() ?? '';
    final args = arguments['arguments']?.toString();

    if (appName.isEmpty) {
      return ToolResult.failure(
        tool: name,
        error: 'Application name is required.',
      );
    }

    try {
      if (!kIsWeb && Platform.isWindows) {
        return await _launchWindowsApp(appName, args);
      } else {
        return ToolResult.success(
          tool: name,
          message: 'Web rejimida simulyatsiya qilindi: $appName ochildi.',
          data: {'application': appName},
        );
      }
    } catch (e) {
      JarvisLogger.error('Failed to open application $appName', e);
      return ToolResult.failure(
        tool: name,
        error: 'Failed to launch $appName: $e',
      );
    }
  }

  Future<ToolResult> _launchWindowsApp(String appName, String? args) async {
    String command = '';
    List<String> commandArgs = [];

    switch (appName) {
      case 'vscode':
      case 'vs code':
      case 'visual studio code':
      case 'code':
        command = 'cmd.exe';
        commandArgs = ['/c', 'code', if (args != null && args.isNotEmpty) args];
        break;

      case 'chrome':
      case 'google chrome':
        command = 'cmd.exe';
        commandArgs = ['/c', 'start', 'chrome', if (args != null && args.isNotEmpty) args];
        break;

      case 'edge':
      case 'microsoft edge':
        command = 'cmd.exe';
        commandArgs = ['/c', 'start', 'msedge', if (args != null && args.isNotEmpty) args];
        break;

      case 'telegram':
        command = 'cmd.exe';
        commandArgs = ['/c', 'start', 'telegram:'];
        break;

      case 'notepad':
        command = 'notepad.exe';
        if (args != null && args.isNotEmpty) commandArgs.add(args);
        break;

      case 'calc':
      case 'calculator':
        command = 'calc.exe';
        break;

      case 'explorer':
      case 'files':
        command = 'explorer.exe';
        if (args != null && args.isNotEmpty) commandArgs.add(args);
        break;

      case 'terminal':
      case 'powershell':
        command = 'cmd.exe';
        commandArgs = ['/c', 'start', 'powershell'];
        break;

      default:
        command = 'cmd.exe';
        commandArgs = ['/c', 'start', '""', appName, if (args != null && args.isNotEmpty) args];
        break;
    }

    JarvisLogger.info('Launching application command: $command with args: $commandArgs');

    final process = await Process.start(
      command,
      commandArgs,
      mode: ProcessStartMode.detached,
      runInShell: true,
    );

    return ToolResult.success(
      tool: name,
      message: 'Successfully launched $appName.',
      data: {'pid': process.pid, 'application': appName},
    );
  }
}
