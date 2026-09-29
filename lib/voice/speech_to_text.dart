import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Function(String words, bool isFinal)? onResult;
  Function(double soundLevel)? onSoundLevelChange;
  Function(bool isListening)? onListeningStateChanged;

  Future<bool> init() async {
    if (_isAvailable) return true;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          JarvisLogger.info('STT Status: $status');
          if (status == 'listening') {
            _isListening = true;
            onListeningStateChanged?.call(true);
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
            onListeningStateChanged?.call(false);
          }
        },
        onError: (errorNotification) {
          JarvisLogger.error('STT Error: ${errorNotification.errorMsg}');
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
      );
      return _isAvailable;
    } catch (e) {
      JarvisLogger.error('STT Initialization error', e);
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({String? localeId}) async {
    if (!_isAvailable) {
      final ok = await init();
      if (!ok) return;
    }

    if (_isListening) return;

    final config = AppConfig();
    final locale = localeId ?? config.language;

    try {
      await _speech.listen(
        onResult: (result) {
          onResult?.call(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: (level) {
          onSoundLevelChange?.call(level);
        },
        localeId: locale,
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
      _isListening = true;
      onListeningStateChanged?.call(true);
    } catch (e) {
      JarvisLogger.error('STT listen error', e);
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
    } catch (_) {}
  }
}
