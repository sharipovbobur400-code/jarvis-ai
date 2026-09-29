import '../core/storage/local_database.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final LocalDatabaseService _db = LocalDatabaseService();

  Future<void> processUserMessageForMemories(String message) async {
    final lower = message.toLowerCase().trim();

    // Name detection: "meni Bobur deb chaqir", "mening ismim Ali", "my name is John"
    if (lower.contains('deb chaqir') || lower.contains('ismim') || lower.contains('mening ismim')) {
      final match = RegExp(r'(?:meni\s+|ismim\s+|mening\s+ismim\s+)([A-ZА-Яa-zа-я\w]+)(?:\s+deb\s+chaqir|\s+bo\x27lsin)?', caseSensitive: false).firstMatch(message);
      if (match != null && match.group(1) != null) {
        final name = match.group(1)!.trim();
        if (name.isNotEmpty && name.toLowerCase() != 'jarvis') {
          await AppConfig().setUserName(name);
          await _db.saveMemory('user_name', name, category: 'profile');
          JarvisLogger.info('User name remembered: $name');
        }
      }
    }

    // Language preference detection
    if (lower.contains('o\'zbekcha gapir') || lower.contains('o‘zbekcha gapir') || lower.contains('uzbek')) {
      await AppConfig().setLanguage('uz-UZ');
      await _db.saveMemory('language', 'uz-UZ', category: 'preferences');
    } else if (lower.contains('говори по-русски') || lower.contains('по русски') || lower.contains('russian')) {
      await AppConfig().setLanguage('ru-RU');
      await _db.saveMemory('language', 'ru-RU', category: 'preferences');
    } else if (lower.contains('speak english') || lower.contains('in english')) {
      await AppConfig().setLanguage('en-US');
      await _db.saveMemory('language', 'en-US', category: 'preferences');
    }
  }
}
