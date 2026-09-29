import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'base_tool.dart';
import '../core/utils/logger.dart';

class BrowserTool extends BaseJarvisTool {
  @override
  String get name => 'browser_action';

  @override
  String get description => 'Opens URLs, searches Google, or plays music/videos on YouTube in Google Chrome or default browser.';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': ['open_url', 'search_google', 'play_youtube'],
        'description': 'The browser action to perform',
      },
      'query': {
        'type': 'string',
        'description': 'Search query or URL or song title',
      },
    },
    'required': ['action', 'query'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final action = arguments['action']?.toString() ?? 'open_url';
    final query = arguments['query']?.toString() ?? '';

    if (query.isEmpty) {
      return ToolResult.failure(tool: name, error: 'Query or URL cannot be empty.');
    }

    try {
      String targetUrl = '';
      if (action == 'search_google') {
        final encoded = Uri.encodeComponent(query);
        targetUrl = 'https://www.google.com/search?q=$encoded';
      } else if (action == 'play_youtube') {
        final encoded = Uri.encodeComponent(query);
        targetUrl = 'https://www.youtube.com/results?search_query=$encoded';
      } else {
        if (!query.startsWith('http://') && !query.startsWith('https://')) {
          targetUrl = 'https://$query';
        } else {
          targetUrl = query;
        }
      }

      JarvisLogger.info('Opening URL in browser: $targetUrl');

      if (!kIsWeb && Platform.isWindows) {
        try {
          await Process.start('cmd.exe', ['/c', 'start', 'chrome', targetUrl]);
          return ToolResult.success(
            tool: name,
            message: 'Opened in Chrome: $query',
            data: {'url': targetUrl, 'action': action},
          );
        } catch (_) {
          final uri = Uri.parse(targetUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return ToolResult.success(
            tool: name,
            message: 'Opened in browser: $query',
            data: {'url': targetUrl, 'action': action},
          );
        }
      } else {
        final uri = Uri.parse(targetUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return ToolResult.success(
          tool: name,
          message: 'Opened URL: $targetUrl',
          data: {'url': targetUrl},
        );
      }
    } catch (e) {
      JarvisLogger.error('Browser action failed', e);
      return ToolResult.failure(tool: name, error: 'Browser action failed: $e');
    }
  }
}
