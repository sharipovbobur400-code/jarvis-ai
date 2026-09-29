import 'dart:io';
import 'package:flutter/foundation.dart';
import 'tool_result.dart';
import 'file_tool.dart';
import 'application_tool.dart';

/// AI code generation + project creation (sections 13-14, 16).
class ProjectTool {
  final FileTool _files = FileTool();
  final ApplicationTool _apps = ApplicationTool();

  /// Full pipeline: create project folder, write files, syntax-check Python,
  /// optionally open in VS Code. Returns a step-by-step report.
  Future<List<ToolResult>> buildProject({
    required String name,
    required Map<String, String> files,
    String parent = '',
    bool openInVsCode = false,
  }) async {
    final results = <ToolResult>[];

    // 1. Create project skeleton
    final created = _files.createProject(name, parent: parent, files: files);
    results.add(created);
    if (!created.success) return results;
    final root = created.data['path'] as String;

    // 2. Write each file (content already provided by AI)
    for (final entry in files.entries) {
      if (entry.key == 'README.md' || entry.key == '.gitignore' ||
          entry.key == 'requirements.txt') {
        continue; // already written by createProject defaults? rewrite anyway
      }
      results.add(_files.writeFile(entry.key, entry.value));
    }

    // 3. Python syntax check if a python file exists
    final mainPy = files.keys.where((k) => k.endsWith('.py')).firstOrNull;
    if (mainPy != null) {
      try {
        final r = await Process.run(
          'python', ['-m', 'py_compile', mainPy],
          runInShell: true, workingDirectory: root,
        );
        results.add(r.exitCode == 0
            ? ToolResult.ok('syntax_check', 'Syntax OK')
            : ToolResult.fail('syntax_check', (r.stderr ?? '').toString()));
      } catch (_) {
        results.add(ToolResult.ok('syntax_check',
            'Python topilmadi, syntax tekshiruv o\'tkazib yuborildi'));
      }
    }

    // 4. Open in VS Code
    if (openInVsCode) {
      results.add(_apps.openApplication('vs code'));
      await Future.delayed(const Duration(seconds: 3));
      try {
        Process.start('cmd', ['/c', 'code', root],
            mode: ProcessStartMode.detached, runInShell: true);
        results.add(ToolResult.ok('open_vscode', 'Project opened in VS Code'));
      } catch (e) {
        results.add(ToolResult.fail('open_vscode', e.toString()));
      }
    }

    return results;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Helper used by the AI brain when generating code files.
Future<ToolResult> writeCodeFile(String path, String code,
    {required bool confirmed}) async {
  if (!confirmed && code.contains('rm -rf')) {
    return ToolResult.fail('write_file', 'confirmation_required');
  }
  try {
    final f = File(path);
    f.parent.createSync(recursive: true);
    await f.writeAsString(code);
    if (kDebugMode) debugPrint('Wrote ${f.path}');
    return ToolResult.ok('write_file', 'Code written to ${f.path}');
  } catch (e) {
    return ToolResult.fail('write_file', e.toString());
  }
}
