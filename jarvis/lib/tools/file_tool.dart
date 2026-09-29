import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'tool_result.dart';

/// Real file-system operations (section 12).
class FileTool {
  String _home() => Platform.environment['USERPROFILE'] ?? '.';

  String resolvePath(String path) {
    var p2 = path.trim();
    if (p2.startsWith('~')) p2 = _home() + p2.substring(1);
    // Common natural-language targets: "Desktopda", "Documentsda".
    for (final known in ['Desktop', 'Documents', 'Downloads', 'Music',
        'Pictures', 'Videos']) {
      final re = RegExp(known, caseSensitive: false);
      if (!p2.contains('\\') && !p2.contains('/') && re.hasMatch(p2)) {
        p2 = p.join(_home(), known);
      } else if (re.hasMatch(p2) && !p2.toLowerCase().contains(known.toLowerCase())) {
        // "Desktopda test papka" -> Desktop\test
        final rest = p2.replaceFirst(re, '').trim();
        p2 = p.join(_home(), known, rest);
      }
    }
    return p.normalize(p2);
  }

  ToolResult createFolder(String path) {
    try {
      final dir = Directory(resolvePath(path));
      dir.createSync(recursive: true);
      return ToolResult.ok('create_folder', 'Created ${dir.path}',
          {'path': dir.path});
    } catch (e) {
      return ToolResult.fail('create_folder', e.toString());
    }
  }

  ToolResult createFile(String path, {String content = ''}) {
    try {
      final file = File(resolvePath(path));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      return ToolResult.ok('create_file', 'Created ${file.path}',
          {'path': file.path});
    } catch (e) {
      return ToolResult.fail('create_file', e.toString());
    }
  }

  ToolResult writeFile(String path, String content) {
    try {
      final file = File(resolvePath(path));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      return ToolResult.ok('write_file', 'Wrote ${file.path}');
    } catch (e) {
      return ToolResult.fail('write_file', e.toString());
    }
  }

  ToolResult readFile(String path) {
    try {
      final f = File(resolvePath(path));
      if (!f.existsSync()) return ToolResult.fail('read_file', 'File not found');
      return ToolResult.ok('read_file', f.readAsStringSync());
    } catch (e) {
      return ToolResult.fail('read_file', e.toString());
    }
  }

  ToolResult openFolder(String path) {
    try {
      final dir = resolvePath(path);
      Process.start('explorer.exe', [dir], mode: ProcessStartMode.detached);
      return ToolResult.ok('open_folder', 'Opened $dir');
    } catch (e) {
      return ToolResult.fail('open_folder', e.toString());
    }
  }

  ToolResult openPath(String path) {
    try {
      final resolved = resolvePath(path);
      final f = File(resolved);
      final d = Directory(resolved);
      if (d.existsSync()) {
        Process.start('explorer.exe', [resolved],
            mode: ProcessStartMode.detached);
      } else if (f.existsSync()) {
        Process.start('explorer.exe', ['/select,', resolved],
            mode: ProcessStartMode.detached);
      } else {
        return ToolResult.fail('open_folder', 'Path not found: $resolved');
      }
      return ToolResult.ok('open_folder', 'Opened $resolved');
    } catch (e) {
      return ToolResult.fail('open_folder', e.toString());
    }
  }

  ToolResult listDirectory(String path) {
    try {
      final dir = Directory(resolvePath(path));
      final items = dir.listSync().take(200).map((e) {
        final name = p.basename(e.path);
        return e is Directory ? '[folder] $name' : '[file] $name';
      }).toList();
      return ToolResult.ok('list_directory', items.join('\n'),
          {'items': items});
    } catch (e) {
      return ToolResult.fail('list_directory', e.toString());
    }
  }

  ToolResult deletePath(String path) {
    try {
      final resolved = resolvePath(path);
      final d = Directory(resolved);
      final f = File(resolved);
      if (d.existsSync()) {
        d.deleteSync(recursive: true);
        return ToolResult.ok('delete_path', 'Deleted folder $resolved');
      } else if (f.existsSync()) {
        f.deleteSync();
        return ToolResult.ok('delete_path', 'Deleted file $resolved');
      }
      return ToolResult.fail('delete_path', 'Path not found: $resolved');
    } catch (e) {
      return ToolResult.fail('delete_path', e.toString());
    }
  }

  /// Creates a standard project skeleton (sections 13-14).
  ToolResult createProject(String name,
      {String parent = '', Map<String, String>? files}) {
    try {
      final parentDir =
          parent.isEmpty ? p.join(_home(), 'Desktop') : resolvePath(parent);
      final root = p.join(parentDir, name);
      Directory(root).createSync(recursive: true);
      final defaultFiles = files ??
          {
            'main.py': '',
            'requirements.txt': '',
            'README.md': '# $name\n',
            '.gitignore': '__pycache__/\n.env\n',
          };
      defaultFiles.forEach((rel, content) {
        final f = File(p.join(root, rel));
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(content);
      });
      return ToolResult.ok('create_project', 'Project created at $root',
          {'path': root});
    } catch (e) {
      return ToolResult.fail('create_project', e.toString());
    }
  }
}
