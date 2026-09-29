import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'tool_result.dart';
import 'application_tool.dart';

/// Chrome / browser control and YouTube music playback (sections 10-11).
class BrowserTool {
  final ApplicationTool _apps = ApplicationTool();

  String? _chromePath() {
    final candidates = [
      r'C:\Program Files\Google\Chrome\Application\chrome.exe',
      r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
      r'C:\Users\maesy\AppData\Local\Google\Chrome\Application\chrome.exe',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  ToolResult openBrowser([String? url]) {
    final chrome = _chromePath();
    try {
      if (chrome != null) {
        Process.start(chrome, [if (url != null) url],
            mode: ProcessStartMode.detached);
      } else {
        // Error recovery (section 29): Edge is always present on Windows.
        final edge =
            r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
        Process.start(edge, [if (url != null) url],
            mode: ProcessStartMode.detached);
      }
      return ToolResult.ok('open_browser',
          chrome != null ? 'Chrome opened' : 'Edge opened (Chrome not found)',
          {'browser': chrome != null ? 'Chrome' : 'Edge'});
    } catch (e) {
      return ToolResult.fail('open_browser', e.toString());
    }
  }

  ToolResult openUrl(String url) {
    try {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return ToolResult.ok('open_url', 'Opened $url');
    } catch (e) {
      return ToolResult.fail('open_url', e.toString());
    }
  }

  ToolResult searchWeb(String query) =>
      openUrl('https://www.google.com/search?q=${Uri.encodeComponent(query)}');

  /// Opens YouTube and starts a search / first result for a song query.
  /// YouTube search URLs autoplay the best match when `first` is used.
  ToolResult playYoutube(String song) {
    final q = Uri.encodeComponent('$song');
    return openUrl('https://www.youtube.com/results?search_query=$q');
  }

  ToolResult openYoutube() => openUrl('https://www.youtube.com');

  ToolResult openVsCode([String? projectPath]) {
    final exe = _apps.resolveExecutable('vs code');
    try {
      final target = exe ?? 'code';
      Process.start(target, [if (projectPath != null) projectPath],
          mode: ProcessStartMode.detached, runInShell: true);
      return ToolResult.ok('open_vscode', 'Visual Studio Code opened');
    } catch (e) {
      return ToolResult.fail('open_vscode', e.toString());
    }
  }
}
