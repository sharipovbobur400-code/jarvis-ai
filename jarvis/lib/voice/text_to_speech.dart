import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech with automatic language detection and female voice
/// preference (sections 5, 8).
class TextToSpeech {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    try {
      await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback, []);
    } catch (_) {}
    // Prefer female voices per language when available.
    try {
      final voices = await _tts.getVoices;
      for (final v in (voices as List).cast<Map>()) {
        final name = '${v['name']}'.toLowerCase();
        final lang = '${v['locale']}'.toLowerCase();
        if (lang.startsWith('uz') ||
            lang.startsWith('ru') ||
            lang.startsWith('en')) {
          final female = name.contains('female') ||
              name.contains('milena') ||
              name.contains('zira') ||
              name.contains('svetlana') ||
              name.contains('alena') ||
              name.contains('woman');
          if (female) {
            await _tts.setVoice({'name': '${v['name']}', 'locale': '${v['locale']}'});
            break;
          }
        }
      }
    } catch (_) {}
    _ready = true;
  }

  String detectLanguage(String text) {
    final cyrillic = RegExp(r'[а-яё]', caseSensitive: false);
    if (cyrillic.hasMatch(text)) return 'ru-RU';
    // Very rough: mostly ascii => english, otherwise uzbek (latin).
    final latin = RegExp(r'^[a-zA-Z0-9\s\.,!?\-\'\"]+$');
    return latin.hasMatch(text) ? 'en-US' : 'uz-UZ';
  }

  Future<void> speak(String text) async {
    if (text.isEmpty || !Platform.isAndroid && !Platform.isIOS &&
        !Platform.isWindows) {
      return;
    }
    await _init();
    final lang = detectLanguage(text);
    if (lang == 'uz-UZ') {
      // Uzbek TTS voices are rare; fall back to Turkish (close phonetics).
      final hasUz = await _hasLanguage('uz');
      await _tts.setLanguage(hasUz ? 'uz-UZ' : 'tr-TR');
    } else {
      await _tts.setLanguage(lang);
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.3); // female-leaning pitch
    await _tts.speak(text);
  }

  Future<bool> _hasLanguage(String prefix) async {
    try {
      final langs = await _tts.getLanguages;
      return (langs as List).any((l) => '$l'.startsWith(prefix));
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() => _tts.stop();
}
