import 'dart:io';

/// Loads environment-style configuration from `.env` (never committed) with
/// sensible fallbacks so the app also runs without it (offline/basic mode).
class AppConfig {
  static final AppConfig instance = AppConfig._();

  final Map<String, String> _values = {};

  AppConfig._() {
    _load();
  }

  void _load() {
    // Try .env next to executable, then in the project working dir.
    final candidates = <String>[
      'C:\\jarvis\\.env',
      '.env',
    ];
    for (final path in candidates) {
      final f = File(path);
      if (f.existsSync()) {
        for (final rawLine in f.readAsLinesSync()) {
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          final idx = line.indexOf('=');
          if (idx <= 0) continue;
          _values[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
        }
        break;
      }
    }
  }

  String get(String key, [String fallback = '']) {
    final v = Platform.environment[key] ?? _values[key];
    return (v == null || v.isEmpty) ? fallback : v;
  }

  String get aiProvider => get('AI_PROVIDER', 'gemini');
  String get aiApiKey => get('AI_API_KEY');
  String get aiModel => get('AI_MODEL', 'gemini-1.5-flash');
  int get remotePort => int.tryParse(get('REMOTE_PORT', '52000')) ?? 52000;
  String get remoteSecret => get('REMOTE_SECRET', 'jarvis-default-secret');

  bool get hasAiKey => aiApiKey.isNotEmpty && aiApiKey != 'YOUR_SECRET_KEY';
}
