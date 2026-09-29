import '../core/config/constants.dart';
import '../core/utils/logger.dart';

class WakeWordDetector {
  static bool containsWakeWord(String text) {
    final lower = text.toLowerCase().trim();
    for (var word in JarvisConstants.wakeWords) {
      if (lower.contains(word)) {
        JarvisLogger.info('Wake word detected: $word');
        return true;
      }
    }
    return false;
  }

  static String stripWakeWord(String text) {
    String cleaned = text.trim();
    for (var word in JarvisConstants.wakeWords) {
      final regex = RegExp('^$word[\\s,.]*', caseSensitive: false);
      cleaned = cleaned.replaceFirst(regex, '').trim();
    }
    return cleaned;
  }
}
