import 'dart:io';
import 'package:flutter/foundation.dart';
import 'base_tool.dart';
import '../core/utils/system_info.dart';
import '../core/utils/logger.dart';

class SystemTool extends BaseJarvisTool {
  @override
  String get name => 'get_system_info';

  @override
  String get description => 'Retrieves live system diagnostics (CPU %, RAM %, Battery %, Time, OS) or executes system operations (lock_pc).';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': ['get_status', 'lock_pc', 'get_time'],
        'description': 'The system action to query or execute',
      },
    },
    'required': ['action'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final action = arguments['action']?.toString() ?? 'get_status';

    try {
      if (action == 'lock_pc') {
        if (!kIsWeb && Platform.isWindows) {
          await Process.run('rundll32.exe', ['user32.dll,LockWorkStation']);
          return ToolResult.success(
            tool: name,
            message: 'Kompyuter qulflandi.',
            data: {'action': 'lock_pc'},
          );
        } else {
          return ToolResult.success(tool: name, message: 'PC qulflash simulyatsiya qilindi.');
        }
      } else if (action == 'get_time') {
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        return ToolResult.success(
          tool: name,
          message: 'Hozirgi vaqt: $timeStr',
          data: {'time': timeStr, 'timestamp': now.toIso8601String()},
        );
      } else {
        final stats = await SystemInfoUtil.getRealWindowsStats();
        return ToolResult.success(
          tool: name,
          message: 'CPU: ${stats.cpuUsage.toStringAsFixed(1)}%, RAM: ${stats.ramUsage.toStringAsFixed(1)}%, Batareya: ${stats.batteryLevel}%',
          data: stats.toJson(),
        );
      }
    } catch (e) {
      JarvisLogger.error('System tool error', e);
      return ToolResult.failure(tool: name, error: 'System action failed: $e');
    }
  }
}
