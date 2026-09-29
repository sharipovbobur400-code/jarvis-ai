import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../ai/ai_service.dart';
import '../core/utils/system_info.dart';
import '../core/utils/logger.dart';

// Server (Runs on Desktop)
class JarvisRemoteServer {
  static final JarvisRemoteServer _instance = JarvisRemoteServer._internal();
  factory JarvisRemoteServer() => _instance;
  JarvisRemoteServer._internal();

  HttpServer? _server;
  final List<WebSocketChannel> _connectedClients = [];
  Timer? _metricsTimer;
  bool get isRunning => _server != null;

  Function(String message)? onCommandReceived;

  Future<bool> startServer(int port) async {
    if (_server != null) return true;

    try {
      final handler = webSocketHandler((WebSocketChannel webSocket) {
        _connectedClients.add(webSocket);
        JarvisLogger.info('Remote mobile client connected.');

        webSocket.stream.listen((message) async {
          try {
            final data = jsonDecode(message.toString()) as Map<String, dynamic>;
            final type = data['type'] as String?;

            if (type == 'command') {
              final text = data['text'] as String? ?? '';
              onCommandReceived?.call(text);
              final response = await AIService().processUserCommand(text);

              webSocket.sink.add(jsonEncode({
                'type': 'response',
                'text': response,
                'timestamp': DateTime.now().toIso8601String(),
              }));
            }
          } catch (e) {
            JarvisLogger.error('Error handling socket message', e);
          }
        }, onDone: () {
          _connectedClients.remove(webSocket);
          JarvisLogger.info('Remote mobile client disconnected.');
        });
      });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      JarvisLogger.info('JARVIS WebSocket server listening on port ${_server!.port}');

      // Start periodic telemetry broadcast
      _metricsTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (_connectedClients.isNotEmpty) {
          final stats = await SystemInfoUtil.getRealWindowsStats();
          final payload = jsonEncode({
            'type': 'telemetry',
            'data': stats.toJson(),
          });
          for (var client in _connectedClients) {
            client.sink.add(payload);
          }
        }
      });

      return true;
    } catch (e) {
      JarvisLogger.error('Failed to start WebSocket server', e);
      return false;
    }
  }

  Future<void> stopServer() async {
    _metricsTimer?.cancel();
    for (var client in _connectedClients) {
      await client.sink.close();
    }
    _connectedClients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}

// Client (Runs on Android Remote App)
class JarvisRemoteClient {
  static final JarvisRemoteClient _instance = JarvisRemoteClient._internal();
  factory JarvisRemoteClient() => _instance;
  JarvisRemoteClient._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  SystemStats? latestStats;
  Function(SystemStats stats)? onStatsReceived;
  Function(String text)? onResponseReceived;
  Function(bool connected)? onConnectionChanged;

  Future<bool> connect(String ip, int port) async {
    disconnect();
    try {
      final uri = Uri.parse('ws://$ip:$port');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message.toString()) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'telemetry' && data['data'] != null) {
            final s = data['data'];
            latestStats = SystemStats(
              cpuUsage: (s['cpuUsage'] as num?)?.toDouble() ?? 0.0,
              ramUsage: (s['ramUsage'] as num?)?.toDouble() ?? 0.0,
              totalRamGb: (s['totalRamGb'] as num?)?.toDouble() ?? 16.0,
              usedRamGb: (s['usedRamGb'] as num?)?.toDouble() ?? 0.0,
              batteryLevel: (s['batteryLevel'] as num?)?.toInt() ?? 100,
              isCharging: s['isCharging'] as bool? ?? true,
              osName: s['osName'] as String? ?? 'Windows',
            );
            onStatsReceived?.call(latestStats!);
          } else if (type == 'response') {
            onResponseReceived?.call(data['text'] ?? '');
          }
        } catch (e) {
          JarvisLogger.error('Error parsing remote response', e);
        }
      }, onDone: () {
        _isConnected = false;
        onConnectionChanged?.call(false);
      }, onError: (err) {
        _isConnected = false;
        onConnectionChanged?.call(false);
      });

      _isConnected = true;
      onConnectionChanged?.call(true);
      return true;
    } catch (e) {
      _isConnected = false;
      onConnectionChanged?.call(false);
      return false;
    }
  }

  void sendCommand(String text) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'command',
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    onConnectionChanged?.call(false);
  }
}
