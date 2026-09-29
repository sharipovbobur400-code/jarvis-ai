import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Speech-to-text. Android/iOS uses the native recognizer; on Windows it
/// reports unsupported so the UI falls back to the text input field.
class SpeechToTextService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _available = false;

  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  Future<bool> init() async {
    if (!isSupported) return false;
    _available = await _stt.initialize();
    return _available;
  }

  void listen({
    required void Function(String text) onResult,
    required void Function(bool listening) onListeningChanged,
    String locale = 'uz-UZ',
  }) {
    if (!_available) {
      init().then((ok) {
        if (ok) {
          listen(onResult: onResult, onListeningChanged: onListeningChanged, locale: locale);
        } else {
          onListeningChanged(false);
        }
      });
      return;
    }
    _stt.listen(
      localeId: locale,
      listenOptions: stt.ListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (r) => onResult(r.recognizedWords ?? ''),
      onSoundLevelChange: (_) {},
      onCancel: () => onListeningChanged(false),
      onError: (_) => onListeningChanged(false),
    );
    onListeningChanged(true);
  }

  Future<void> stop() async {
    await _stt.stop();
  }
}

/// Wake-word detector: checks whether recognized text starts with JARVIS
/// (section 7) and strips the wake word from the command.
class WakeWordDetector {
  static final _wake = RegExp(r'^(hey\s+|ok\s+)?jarvis[\s,\.!:]*', caseSensitive: false);

  /// Returns null if no wake word; otherwise the remaining command (may be
  /// empty meaning "just activated, start listening").
  String? extract(String text) {
    final m = _wake.firstMatch(text.trim());
    if (m == null) return null;
    return text.trim().substring(m.end).trim();
  }

  bool hasWakeWord(String text) => _wake.hasMatch(text.trim());
}
