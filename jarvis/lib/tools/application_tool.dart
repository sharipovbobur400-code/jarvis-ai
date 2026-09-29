import 'dart:io';
import 'tool_result.dart';

/// Opens and closes real Windows applications (section 9).
/// Resolves apps from PATH, common install locations and the Start Menu.
class ApplicationTool {
  static const knownApps = <String, List<String>>{
    'chrome': ['chrome.exe'],
    'google chrome': ['chrome.exe'],
    'notepad': ['notepad.exe'],
    'calculator': ['calc.exe'],
    'paint': ['mspaint.exe'],
    'explorer': ['explorer.exe'],
    'cmd': ['cmd.exe'],
    'powershell': ['powershell.exe'],
    'task manager': ['taskmgr.exe'],
    'vscode': ['code.cmd', 'code.exe'],
    'vs code': ['code.cmd', 'code.exe'],
    'visual studio code': ['code.cmd', 'code.exe'],
    'telegram': ['telegram.exe'],
    'spotify': ['spotify.exe'],
    'discord': ['discord.exe'],
    'word': ['winword.exe'],
    'excel': ['excel.exe'],
    'steam': ['steam.exe'],
    'firefox': ['firefox.exe'],
    'edge': ['msedge.exe'],
  };

  final List<String> _searchDirs = [
    r'C:\Program Files',
    r'C:\Program Files (x86)',
    r'C:\Users\maesy\AppData\Local',
    r'C:\Users\maesy\AppData\Roaming',
  ];

  /// Finds an executable on disk for the given app name.
  String? resolveExecutable(String appName) {
    final key = appName.toLowerCase().trim();
    final exes = knownApps[key] ?? ['${key.replaceAll(' ', '')}.exe'];

    for (final exe in exes) {
      // 1. Already on PATH / system app?
      final which = Process.runSync('where', [exe], runInShell: true);
      if (which.exitCode == 0 && (which.stdout as String).trim().isNotEmpty) {
        return exe; // resolvable via PATH
      }
      // 2. Search common install directories (depth-limited).
      for (final dir in _searchDirs) {
        final found = _searchDir(Directory(dir), exe, depth: 0);
        if (found != null) return found;
      }
      // 3. Start Menu shortcuts via PowerShell.
      if (exe.endsWith('.exe')) {
        final shortcut = _resolveViaStartMenu(appName);
        if (shortcut != null) return shortcut;
      }
    }
    return null;
  }

  String? _searchDir(Directory dir, String exe, {int depth = 0}) {
    if (depth > 3 || !dir.existsSync()) return null;
    try {
      for (final e in dir.listSync(followLinks: false)) {
        if (e is File && e.path.toLowerCase().endsWith(exe)) return e.path;
        if (e is Directory) {
          final r = _searchDir(e, exe, depth: depth + 1);
          if (r != null) return r;
        }
      }
    } catch (_) {}
    return null;
  }

  String? _resolveViaStartMenu(String appName) {
    try {
      final script = '''
\$n = "$appName*"
\$dirs = @("\$env:APPDATA\\Microsoft\\Windows\\Start Menu", "\$env:ProgramData\\Microsoft\\Windows\\Start Menu")
foreach (\$d in \$dirs) {
  \$lnk = Get-ChildItem \$d -Recurse -Filter \$n -ErrorAction SilentlyContinue | Select-Object -First 1
  if (\$lnk) {
    \$sh = New-Object -ComObject WScript.Shell
    \$target = \$sh.CreateShortcut(\$lnk.FullName).TargetPath
    if (\$target) { Write-Output \$target; exit }
  }
}
''';
      final r = Process.runSync('powershell', ['-NoProfile', '-Command', script],
          runInShell: true);
      final out = (r.stdout as String).trim();
      if (r.exitCode == 0 && out.isNotEmpty && out.endsWith('.exe')) {
        return out;
      }
    } catch (_) {}
    return null;
  }

  ToolResult openApplication(String appName) {
    final exe = resolveExecutable(appName);
    try {
      if (exe != null && File(exe).existsSync()) {
        Process.start(exe, [], mode: ProcessStartMode.detached);
        return ToolResult.ok(
            'open_application', '$appName opened successfully',
            {'application': appName});
      }
      // Fall back to shell resolution (PATH, protocol handlers).
      Process.start('cmd', ['/c', 'start', '', appName],
          mode: ProcessStartMode.detached, runInShell: true);
      return ToolResult.ok('open_application', '$appName opened successfully',
          {'application': appName});
    } catch (e) {
      return ToolResult.fail('open_application', 'Application not found: $e');
    }
  }

  ToolResult closeApplication(String appName) {
    final exe = resolveExecutable(appName);
    final procName = exe != null
        ? exe.split(Platform.pathSeparator).last
        : '${appName.replaceAll(' ', '').toLowerCase()}.exe';
    try {
      final r = Process.runSync('taskkill',
          ['/IM', procName, '/F'], runInShell: true);
      final success = r.exitCode == 0;
      return success
          ? ToolResult.ok('close_application', '$appName closed')
          : ToolResult.fail(
              'close_application', 'Process not found: $procName');
    } catch (e) {
      return ToolResult.fail('close_application', e.toString());
    }
  }

  /// Lists installed Start-Menu applications for discovery / error recovery.
  List<String> listInstalledApplications() {
    final apps = <String>[];
    final dirs = [
      r'C:\ProgramData\Microsoft\Windows\Start Menu\Programs',
      r'C:\Users\maesy\AppData\Roaming\Microsoft\Windows\Start Menu\Programs',
    ];
    for (final d in dirs) {
      final dir = Directory(d);
      if (!dir.existsSync()) continue;
      try {
        for (final e in dir.listSync(recursive: true)) {
          if (e is File && e.path.toLowerCase().endsWith('.lnk')) {
            apps.add(e.uri.pathSegments.last.replaceAll('.lnk', ''));
          }
        }
      } catch (_) {}
    }
    return apps;
  }
}
