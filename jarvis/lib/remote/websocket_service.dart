import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// WebSocket server on the Desktop that the JARVIS Remote Android app
/// connects to (sections 22-24). Simple shared-secret auth with device tokens.
class RemoteServer {
  final int port;
  final String secret;
  HttpServer? _server;
  final Set<WebSocket> _clients = {};
  final Map<String, DateTime> _devices = {};

  final _commands = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get commandStream => _commands.stream;

  RemoteServer({this.port = 52000, this.secret = 'jarvis-default-secret'});

  bool get isRunning => _server != null;

  Future<void> start() async {
    _server ??= await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_onRequest);
  }

  Future<void> stop() async {
    for (final c in _clients) {
      await c.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (req.uri.path == '/pair' && req.method == 'POST') {
      // Pairing: client proves it knows the secret; we issue a device token.
      final body = await utf8.decoder.bind(req).join();
      final json = jsonDecode(body) as Map<String, dynamic>? ?? {};
      final hash = sha256.convert(utf8.encode('${json['secret']}:$secret')).toString();
      if (hash != json['hash']) {
        req.response.statusCode = 401;
        await req.response.close();
        return;
      }
      final token = const Uuid().v4();
      _devices[token] = DateTime.now();
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'token': token}));
      await req.response.close();
      return;
    }

    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(req);
    // First message must be auth: {"token": "..."} issued at /pair.
    final token = await socket.first.timeout(const Duration(seconds: 5),
        onTimeout: (sink) => sink.close());
    if (token is! String || !_devices.containsKey(token)) {
      await socket.close();
      return;
    }
    _clients.add(socket);
    socket.listen(
      (data) {
        try {
          final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
          if (msg['type'] == 'command') {
            _commands.add(msg);
          }
        } catch (_) {}
      },
      onDone: () => _clients.remove(socket),
    );
  }

  /// Broadcasts laptop status to all paired phones (section 22).
  void broadcastStatus(Map<String, dynamic> status) {
    final payload = jsonEncode({'type': 'status', ...status});
    for (final c in _clients) {
      if (c.readyState == WebSocket.open) c.add(payload);
    }
  }
}
