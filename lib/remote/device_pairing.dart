import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'authentication.dart';

class PairingPayload {
  final String ipAddress;
  final int port;
  final String token;
  final String deviceName;

  PairingPayload({
    required this.ipAddress,
    required this.port,
    required this.token,
    required this.deviceName,
  });

  String toQrString() {
    return jsonEncode({
      'ip': ipAddress,
      'port': port,
      'token': token,
      'name': deviceName,
    });
  }

  factory PairingPayload.fromQrString(String qrStr) {
    final data = jsonDecode(qrStr) as Map<String, dynamic>;
    return PairingPayload(
      ipAddress: data['ip'] ?? '127.0.0.1',
      port: data['port'] ?? 8888,
      token: data['token'] ?? '',
      deviceName: data['name'] ?? 'Windows PC',
    );
  }
}

class DevicePairingService {
  static Future<String> getLocalIpAddress() async {
    if (kIsWeb) return '127.0.0.1';

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  static Future<PairingPayload> createPairingPayload(int port) async {
    final ip = await getLocalIpAddress();
    final token = RemoteAuth.generatePairingToken('jarvis_salt_99');
    final name = kIsWeb ? 'Web Browser' : Platform.localHostname;
    return PairingPayload(
      ipAddress: ip,
      port: port,
      token: token,
      deviceName: name,
    );
  }
}
