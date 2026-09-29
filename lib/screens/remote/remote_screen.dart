import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/config/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/system_info.dart';
import '../../remote/websocket_service.dart';
import '../../remote/device_pairing.dart';
import '../../widgets/quick_command_button.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final JarvisRemoteServer _server = JarvisRemoteServer();
  final JarvisRemoteClient _client = JarvisRemoteClient();

  PairingPayload? _pairingPayload;
  bool _isServerRunning = false;
  String _serverIp = '127.0.0.1';

  // Client mode state
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.');
  final TextEditingController _commandController = TextEditingController();
  bool _isClientConnected = false;
  SystemStats? _remoteStats;
  String _remoteResponse = '';

  @override
  void initState() {
    super.initState();
    _initServer();
    _client.onConnectionChanged = (connected) {
      if (mounted) setState(() => _isClientConnected = connected);
    };
    _client.onStatsReceived = (stats) {
      if (mounted) setState(() => _remoteStats = stats);
    };
    _client.onResponseReceived = (resp) {
      if (mounted) setState(() => _remoteResponse = resp);
    };
  }

  void _initServer() async {
    final port = AppConfig().remoteServerPort;
    final payload = await DevicePairingService.createPairingPayload(port);
    final started = await _server.startServer(port);

    if (mounted) {
      setState(() {
        _pairingPayload = payload;
        _serverIp = payload.ipAddress;
        _isServerRunning = started;
      });
    }
  }

  void _connectAsClient() async {
    final ip = _ipController.text.trim();
    final port = AppConfig().remoteServerPort;
    await _client.connect(ip, port);
  }

  void _sendClientCommand(String text) {
    if (text.isEmpty) return;
    _client.sendCommand(text);
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MASOFAVIY BOSHQARUV (REMOTE)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DESKTOP SERVER PAIRING SECTION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded, color: JarvisTheme.primaryCyan),
                            SizedBox(width: 10),
                            Text(
                              'Laptop Server & QR Pairing',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JarvisTheme.textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isServerRunning ? JarvisTheme.success.withOpacity(0.2) : JarvisTheme.danger.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isServerRunning ? JarvisTheme.success : JarvisTheme.danger),
                          ),
                          child: Text(
                            _isServerRunning ? 'SERVER FAOL' : 'SERVER TO‘XTAGAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isServerRunning ? JarvisTheme.success : JarvisTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Android telefondagi JARVIS ilovasi orqali ushbu QR kodni skanerlang yoki IP manzil orqali ulaning: ws://$_serverIp:${AppConfig().remoteServerPort}',
                      style: const TextStyle(color: JarvisTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_pairingPayload != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _pairingPayload!.toQrString(),
                            version: QrVersions.auto,
                            size: 160.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // MOBILE REMOTE CLIENT CONTROLLER SECTION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_android_rounded, color: JarvisTheme.accentGold),
                        SizedBox(width: 10),
                        Text(
                          'Telefon / Masofaviy Boshqaruvchi Rejimi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JarvisTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ipController,
                            decoration: const InputDecoration(
                              labelText: 'Laptop IP manzili',
                              hintText: '192.168.1.xxx',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isClientConnected ? () => _client.disconnect() : _connectAsClient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isClientConnected ? JarvisTheme.danger : JarvisTheme.primaryCyan,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(_isClientConnected ? 'Uzish' : 'Ulanish'),
                        ),
                      ],
                    ),
                    if (_isClientConnected && _remoteStats != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: JarvisTheme.cardBorder,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Laptop CPU: ${_remoteStats!.cpuUsage.toStringAsFixed(0)}%', style: const TextStyle(color: JarvisTheme.primaryCyan)),
                            Text('RAM: ${_remoteStats!.ramUsage.toStringAsFixed(0)}%', style: const TextStyle(color: JarvisTheme.accentGold)),
                            Text('Batareya: ${_remoteStats!.batteryLevel}%', style: const TextStyle(color: JarvisTheme.success)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Quick Remote Commands
                    const Text('Tezkor buyruqlar:', style: TextStyle(color: JarvisTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        QuickCommandButton(
                          label: 'Chrome och',
                          icon: Icons.public,
                          onTap: () => _sendClientCommand('Google Chrome och'),
                        ),
                        QuickCommandButton(
                          label: 'YouTube M1nor',
                          icon: Icons.play_arrow,
                          onTap: () => _sendClientCommand('YouTube orqali M1nor musiqasini qidir va ijro et'),
                        ),
                        QuickCommandButton(
                          label: 'VS Code och',
                          icon: Icons.code,
                          onTap: () => _sendClientCommand('Visual Studio Code och'),
                        ),
                        QuickCommandButton(
                          label: 'Ovozni balandlat',
                          icon: Icons.volume_up,
                          onTap: () => _sendClientCommand('Ovozni oshir'),
                        ),
                        QuickCommandButton(
                          label: 'PC Qulflash',
                          icon: Icons.lock,
                          color: JarvisTheme.danger,
                          onTap: () => _sendClientCommand('Kompyuterni qulfla'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commandController,
                            onSubmitted: (val) => _sendClientCommand(val),
                            decoration: const InputDecoration(
                              hintText: 'Telefondan buyruq yuborish...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send),
                          onPressed: () => _sendClientCommand(_commandController.text),
                        ),
                      ],
                    ),
                    if (_remoteResponse.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Laptop javobi: $_remoteResponse',
                        style: const TextStyle(color: JarvisTheme.primaryCyan, fontSize: 13),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
