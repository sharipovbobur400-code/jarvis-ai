import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MemoryItem {
  final String key;
  final String value;
  final String category;
  final DateTime updatedAt;

  MemoryItem({
    required this.key,
    required this.value,
    required this.category,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'category': category,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MemoryItem.fromJson(Map<String, dynamic> json) => MemoryItem(
    key: json['key'] as String,
    value: json['value'] as String,
    category: json['category'] as String? ?? 'general',
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
  );
}

class ConversationMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system', 'tool'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
    id: json['id'] as String,
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  File? _memoryFile;
  File? _historyFile;

  final Map<String, MemoryItem> _memories = {};
  final List<ConversationMessage> _history = [];

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final jarvisDir = Directory('${dir.path}/JARVIS_Data');
      if (!await jarvisDir.exists()) {
        await jarvisDir.create(recursive: true);
      }

      _memoryFile = File('${jarvisDir.path}/jarvis_memory.json');
      _historyFile = File('${jarvisDir.path}/jarvis_history.json');

      if (await _memoryFile!.exists()) {
        final content = await _memoryFile!.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          data.forEach((key, val) {
            _memories[key] = MemoryItem.fromJson(val);
          });
        }
      }

      if (await _historyFile!.exists()) {
        final content = await _historyFile!.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> list = jsonDecode(content);
          for (var item in list) {
            _history.add(ConversationMessage.fromJson(item));
          }
        }
      }
    } catch (e) {
      // Fallback in-memory
    }
  }

  Future<void> saveMemory(String key, String value, {String category = 'general'}) async {
    final item = MemoryItem(
      key: key,
      value: value,
      category: category,
      updatedAt: DateTime.now(),
    );
    _memories[key] = item;
    await _persistMemory();
  }

  MemoryItem? getMemory(String key) => _memories[key];

  List<MemoryItem> getAllMemories() => _memories.values.toList();

  Future<void> deleteMemory(String key) async {
    _memories.remove(key);
    await _persistMemory();
  }

  Future<void> _persistMemory() async {
    if (_memoryFile != null) {
      final map = _memories.map((k, v) => MapEntry(k, v.toJson()));
      await _memoryFile!.writeAsString(jsonEncode(map));
    }
  }

  Future<void> addMessage(ConversationMessage msg) async {
    _history.add(msg);
    if (_history.length > 200) {
      _history.removeAt(0); // keep last 200 messages
    }
    if (_historyFile != null) {
      await _historyFile!.writeAsString(
        jsonEncode(_history.map((e) => e.toJson()).toList()),
      );
    }
  }

  List<ConversationMessage> getRecentMessages([int count = 20]) {
    if (_history.length <= count) return List.from(_history);
    return _history.sublist(_history.length - count);
  }

  Future<void> clearHistory() async {
    _history.clear();
    if (_historyFile != null && await _historyFile!.exists()) {
      await _historyFile!.writeAsString('[]');
    }
  }
}
