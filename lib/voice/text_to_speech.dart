import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Function(bool isSpeaking)? onSpeakingChanged;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final config = AppConfig();

      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(config.speechRate);
      await _flutterTts.setPitch(config.speechPitch);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingChanged?.call(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
        JarvisLogger.error('TTS error: $msg');
      });

      _isInitialized = true;
      JarvisLogger.info('TTS Service initialized successfully');
    } catch (e) {
      JarvisLogger.error('Failed to initialize TTS Service', e);
    }
  }

  String _detectLanguage(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[а-яё]').hasMatch(lower)) {
      return 'ru-RU';
    } else if (RegExp(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]').hasMatch(text)) {
      return 'ja-JP';
    } else if (RegExp(r'[a-z]').hasMatch(lower)) {
      if (lower.contains('och') || lower.contains('qil') || lower.contains('bajar') || lower.contains('musiqa') || lower.contains('salom')) {
        return 'uz-UZ';
      }
      return 'en-US';
    }
    return AppConfig().language;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await init();
    final lang = _detectLanguage(text);

    try {
      await _flutterTts.setLanguage(lang);
      final config = AppConfig();
      await _flutterTts.setSpeechRate(config.speechRate);
      await _flutterTts.setPitch(config.speechPitch);

      if (!kIsWeb && Platform.isWindows) {
        try {
          final voices = await _flutterTts.getVoices;
          if (voices is List) {
            for (var v in voices) {
              if (v is Map) {
                final name = (v['name'] ?? '').toString().toLowerCase();
                if (name.contains('zira') || name.contains('irina') || name.contains('ayumi') || name.contains('female')) {
                  await _flutterTts.setVoice(Map<String, String>.from(v.cast<String, String>()));
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }

      await _flutterTts.speak(text);
    } catch (e) {
      JarvisLogger.error('TTS speak error', e);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      onSpeakingChanged?.call(false);
    } catch (_) {}
  }
}
