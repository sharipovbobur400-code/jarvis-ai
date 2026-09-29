import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'base_tool.dart';
import '../core/security/security_guard.dart';
import '../core/utils/logger.dart';

class TerminalTool extends BaseJarvisTool {
  @override
  String get name => 'run_terminal_command';

  @override
  String get description => 'Executes shell commands in PowerShell / Windows Command Prompt and returns standard output and errors.';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description': 'The terminal command line to execute',
      },
      'working_directory': {
        'type': 'string',
        'description': 'Optional working directory path',
      },
    },
    'required': ['command'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final command = arguments['command']?.toString().trim() ?? '';
    final workDir = arguments['working_directory']?.toString();

    if (command.isEmpty) {
      return ToolResult.failure(tool: name, error: 'Command cannot be empty.');
    }

    if (kIsWeb) {
      return ToolResult.success(
        tool: name,
        message: 'Web rejimida terminal buyrug‘i simulyatsiya qilindi: $command',
        data: {'command': command, 'exitCode': 0},
      );
    }

    final risk = SecurityGuard().assessTerminalCommand(command);
    if (risk == RiskLevel.high) {
      JarvisLogger.warn('Executing high-risk terminal command: $command');
    }

    try {
      JarvisLogger.info('Running terminal command: $command');

      final ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run(
          'powershell',
          ['-NoProfile', '-NonInteractive', '-Command', command],
          workingDirectory: workDir,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        ).timeout(const Duration(seconds: 45));
      } else {
        result = await Process.run(
          'sh',
          ['-c', command],
          workingDirectory: workDir,
        ).timeout(const Duration(seconds: 45));
      }

      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();

      if (result.exitCode == 0) {
        return ToolResult.success(
          tool: name,
          message: stdout.isNotEmpty ? stdout : 'Command completed successfully with exit code 0.',
          data: {
            'command': command,
            'exitCode': result.exitCode,
            'stdout': stdout,
          },
        );
      } else {
        return ToolResult.failure(
          tool: name,
          error: stderr.isNotEmpty ? stderr : 'Command exited with code ${result.exitCode}',
          data: {
            'command': command,
            'exitCode': result.exitCode,
            'stdout': stdout,
            'stderr': stderr,
          },
        );
      }
    } catch (e) {
      JarvisLogger.error('Terminal command execution failed: $command', e);
      return ToolResult.failure(tool: name, error: 'Execution error: $e');
    }
  }
}
