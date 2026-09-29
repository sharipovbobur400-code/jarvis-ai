import 'package:flutter/foundation.dart';

class JarvisLogger {
  static void info(String message, [String? tag]) {
    debugPrint('[JARVIS:INFO${tag != null ? ':$tag' : ''}] $message');
  }

  static void warn(String message, [String? tag]) {
    debugPrint('[JARVIS:WARN${tag != null ? ':$tag' : ''}] ⚠️ $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    debugPrint('[JARVIS:ERROR${tag != null ? ':$tag' : ''}] ❌ $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }

  static void tool(String toolName, String action, {bool success = true}) {
    final symbol = success ? '✓' : '✗';
    debugPrint('[JARVIS:TOOL] $symbol $toolName -> $action');
  }
}
