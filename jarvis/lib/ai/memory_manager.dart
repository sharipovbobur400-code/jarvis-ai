import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Persistent memory (section 18): user profile, preferences, conversation
/// history and saved facts, stored in local SQLite. Sensitive values are
/// stored via flutter_secure_storage instead.
class MemoryManager {
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    final dir = await getApplicationSupportDirectory();
    _db = await databaseFactoryFfi.openDatabase(
      p.join(dir.path, 'jarvis.db'),
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT,
        content TEXT,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE facts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT,
        content TEXT,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        steps TEXT,
        status TEXT,
        created_at TEXT
      )
    ''');
  }

  // ---- Profile (name, language, voice, preferences) ----
  Future<void> setProfile(String key, String value) async {
    final d = await db;
    await d.insert('profile',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getProfile(String key) async {
    final d = await db;
    final rows =
        await d.query('profile', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  // ---- Conversation context ----
  Future<void> addMessage(String role, String content) async {
    final d = await db;
    await d.insert('messages', {
      'role': role,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
    // Keep last 100 messages as context window.
    await d.execute(
        'DELETE FROM messages WHERE id NOT IN '
        '(SELECT id FROM messages ORDER BY id DESC LIMIT 100)');
  }

  Future<List<Map<String, String>>> recentMessages({int limit = 20}) async {
    final d = await db;
    final rows = await d.query('messages',
        orderBy: 'id DESC', limit: limit);
    return rows.reversed
        .map((r) => {'role': r['role'] as String, 'content': r['content'] as String})
        .toList();
  }

  // ---- Long-term facts ("meni Bobur deb chaqir" -> profile; other facts) ----
  Future<void> rememberFact(String topic, String content) async {
    final d = await db;
    await d.insert('facts', {
      'topic': topic,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> facts() async {
    final d = await db;
    final rows = await d.query('facts', orderBy: 'id DESC', limit: 50);
    return rows.map((r) => '${r['topic']}: ${r['content']}').toList();
  }

  // ---- Task history ----
  Future<int> saveTask(String title, String stepsJson) async {
    final d = await db;
    return d.insert('tasks', {
      'title': title,
      'steps': stepsJson,
      'status': 'done',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> taskHistory({int limit = 50}) async {
    final d = await db;
    return d.query('tasks', orderBy: 'id DESC', limit: limit);
  }
}
