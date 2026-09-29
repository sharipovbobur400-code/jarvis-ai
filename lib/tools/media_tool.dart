import 'dart:io';
import 'package:flutter/foundation.dart';
import 'base_tool.dart';
import '../core/utils/logger.dart';

class MediaTool extends BaseJarvisTool {
  @override
  String get name => 'control_media';

  @override
  String get description => 'Controls system audio volume and media playback (play, pause, next, previous, volume_up, volume_down, mute).';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'enum': ['play_pause', 'next', 'previous', 'volume_up', 'volume_down', 'mute', 'set_volume'],
        'description': 'The media command to execute',
      },
      'level': {
        'type': 'number',
        'description': 'Target volume level (0 to 100) if command is set_volume',
      },
    },
    'required': ['command'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final command = arguments['command']?.toString() ?? 'play_pause';

    if (kIsWeb || !Platform.isWindows) {
      return ToolResult.success(
        tool: name,
        message: 'Media buyrug‘i qabul qilindi: $command',
        data: {'command': command},
      );
    }

    try {
      String psScript = '';

      switch (command) {
        case 'play_pause':
          psScript = '(New-Object -ComObject WScript.Shell).SendKeys([char]179)';
          break;
        case 'next':
          psScript = '(New-Object -ComObject WScript.Shell).SendKeys([char]176)';
          break;
        case 'previous':
          psScript = '(New-Object -ComObject WScript.Shell).SendKeys([char]177)';
          break;
        case 'volume_up':
          psScript = '1..5 | ForEach-Object { (New-Object -ComObject WScript.Shell).SendKeys([char]175) }';
          break;
        case 'volume_down':
          psScript = '1..5 | ForEach-Object { (New-Object -ComObject WScript.Shell).SendKeys([char]174) }';
          break;
        case 'mute':
          psScript = '(New-Object -ComObject WScript.Shell).SendKeys([char]173)';
          break;
        case 'set_volume':
          final target = (arguments['level'] as num?)?.toInt() ?? 50;
          psScript = '''
          \$wscript = New-Object -ComObject WScript.Shell
          1..50 | ForEach-Object { \$wscript.SendKeys([char]174) }
          1..${(target / 2).round()} | ForEach-Object { \$wscript.SendKeys([char]175) }
          ''';
          break;
        default:
          psScript = '(New-Object -ComObject WScript.Shell).SendKeys([char]179)';
      }

      await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', psScript]);

      return ToolResult.success(
        tool: name,
        message: 'Media command executed: $command',
        data: {'command': command},
      );
    } catch (e) {
      JarvisLogger.error('Media command failed: $command', e);
      return ToolResult.failure(tool: name, error: 'Failed to execute media command: $e');
    }
  }
}
