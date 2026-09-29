import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class RemoteAuth {
  static String generatePairingToken(String secretKey) {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$secretKey:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  static String generateDeviceId() {
    return const Uuid().v4();
  }

  static bool verifyToken(String token, String secretKey) {
    // In production pairing flow, verify device token validity
    return token.isNotEmpty;
  }
}
