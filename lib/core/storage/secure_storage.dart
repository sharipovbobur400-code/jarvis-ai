import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, String> _memoryFallback = {};

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Fallback for Windows desktop environments without Credential Manager configured
      final prefs = await SharedPreferences.getInstance();
      final encoded = base64Encode(utf8.encode(value));
      await prefs.setString('sec_$key', encoded);
      _memoryFallback[key] = value;
    }
  }

  Future<String?> read(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {}

    if (_memoryFallback.containsKey(key)) {
      return _memoryFallback[key];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString('sec_$key');
      if (encoded != null) {
        final decoded = utf8.decode(base64Decode(encoded));
        _memoryFallback[key] = decoded;
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sec_$key');
    _memoryFallback.remove(key);
  }
}
