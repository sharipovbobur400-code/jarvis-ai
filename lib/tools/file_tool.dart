import 'dart:io';
import 'package:flutter/foundation.dart';
import 'base_tool.dart';
import '../core/utils/logger.dart';

class FileTool extends BaseJarvisTool {
  @override
  String get name => 'file_operations';

  @override
  String get description => 'Performs file and directory operations (create_folder, create_file, write_file, read_file, open_in_explorer).';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'operation': {
        'type': 'string',
        'enum': ['create_folder', 'create_file', 'write_file', 'read_file', 'open_folder'],
        'description': 'The file operation to perform',
      },
      'path': {
        'type': 'string',
        'description': 'Target path (absolute or relative to Desktop / User directory)',
      },
      'content': {
        'type': 'string',
        'description': 'Content to write if operation is write_file or create_file',
      },
    },
    'required': ['operation', 'path'],
  };

  String _resolvePath(String inputPath) {
    var p = inputPath.trim();
    if (kIsWeb) return p;

    final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';

    if (p.toLowerCase().startsWith('desktop/')) {
      p = '$userProfile/Desktop/${p.substring(8)}';
    } else if (p.toLowerCase() == 'desktop' || p.toLowerCase() == 'desktop\\') {
      p = '$userProfile/Desktop';
    } else if (p.toLowerCase().startsWith('documents/')) {
      p = '$userProfile/Documents/${p.substring(10)}';
    } else if (!p.contains(':') && !p.startsWith('/') && !p.startsWith('\\')) {
      p = '$userProfile/Desktop/$p';
    }
    return p.replaceAll('/', '\\');
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final operation = arguments['operation']?.toString() ?? 'create_file';
    final rawPath = arguments['path']?.toString() ?? '';
    final content = arguments['content']?.toString() ?? '';

    if (rawPath.isEmpty) {
      return ToolResult.failure(tool: name, error: 'File path cannot be empty.');
    }

    if (kIsWeb) {
      return ToolResult.success(
        tool: name,
        message: 'Web rejimida fayl amali simulyatsiya qilindi: $operation -> $rawPath',
        data: {'path': rawPath},
      );
    }

    final resolved = _resolvePath(rawPath);

    try {
      switch (operation) {
        case 'create_folder':
          final dir = Directory(resolved);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return ToolResult.success(
            tool: name,
            message: 'Created folder at $resolved',
            data: {'path': resolved},
          );

        case 'create_file':
        case 'write_file':
          final file = File(resolved);
          final parent = file.parent;
          if (!await parent.exists()) {
            await parent.create(recursive: true);
          }
          await file.writeAsString(content);
          return ToolResult.success(
            tool: name,
            message: 'Successfully wrote file at $resolved',
            data: {'path': resolved, 'size': content.length},
          );

        case 'read_file':
          final file = File(resolved);
          if (!await file.exists()) {
            return ToolResult.failure(tool: name, error: 'File not found at $resolved');
          }
          final fileContent = await file.readAsString();
          return ToolResult.success(
            tool: name,
            message: 'Read file content successfully',
            data: {'path': resolved, 'content': fileContent},
          );

        case 'open_folder':
          if (Platform.isWindows) {
            await Process.start('explorer.exe', [resolved]);
            return ToolResult.success(
              tool: name,
              message: 'Opened folder in Windows Explorer: $resolved',
              data: {'path': resolved},
            );
          } else {
            return ToolResult.failure(tool: name, error: 'Opening folder only supported on Windows.');
          }

        default:
          return ToolResult.failure(tool: name, error: 'Unknown file operation: $operation');
      }
    } catch (e) {
      JarvisLogger.error('File operation failed: $operation at $resolved', e);
      return ToolResult.failure(tool: name, error: 'File operation error: $e');
    }
  }
}
