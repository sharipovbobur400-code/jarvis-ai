import 'dart:io';
import 'tool_result.dart';

/// System information, CPU/RAM, media keys, time (sections 11, 27, 31).
class SystemTool {
  ToolResult getSystemInfo() {
    final info = {
      'os': Platform.operatingSystemVersion,
      'hostname': Platform.localHostname,
      'user': Platform.environment['USERNAME'] ?? '',
      'processors': Platform.numberOfProcessors,
    };
    return ToolResult.ok('get_system_info', info.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n'), info);
  }

  ToolResult getTime() {
    final now = DateTime.now();
    return ToolResult.ok('get_time',
        'Hozir ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        {'time': now.toIso8601String()});
  }

  Future<ToolResult> getCpuUsage() async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-CimInstance Win32_Processor | '
            'Measure-Object -Property LoadPercentage -Average).Average'
      ], runInShell: true);
      return ToolResult.ok('get_cpu_usage',
          'CPU: ${(r.stdout ?? '').trim()}%', {'cpu': (r.stdout ?? '').trim()});
    } catch (e) {
      return ToolResult.fail('get_cpu_usage', e.toString());
    }
  }

  Future<ToolResult> getRamUsage() async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '\$os = Get-CimInstance Win32_OperatingSystem; '
            '[math]::Round((\$os.TotalVisibleMemorySize - \$os.FreePhysicalMemory) / \$os.TotalVisibleMemorySize * 100)'
      ], runInShell: true);
      return ToolResult.ok('get_ram_usage',
          'RAM: ${(r.stdout ?? '').trim()}%', {'ram': (r.stdout ?? '').trim()});
    } catch (e) {
      return ToolResult.fail('get_ram_usage', e.toString());
    }
  }

  ToolResult getNetworkStatus() {
    final nets = List<NetworkInterface>.from(NetworkInterface.list());
    return ToolResult.ok('get_network_status',
        nets.isEmpty ? 'Offline' : 'Online (${nets.length} interface)',
        {'interfaces': nets.map((n) => n.name).toList()});
  }

  /// Sends a virtual media key press via PowerShell (works for Spotify,
  /// YouTube in Chrome, system player).
  ToolResult sendMediaKey(String key) {
    const map = {
      'play_pause': '{F8}',
      'next': '{F9}',
      'previous': '{F10}',
      'stop': '{F11}',
      'volume_up': '{UP}',
      'volume_down': '{DOWN}',
      'mute': '{F12}',
    };
    final code = map[key];
    if (code == null) {
      return ToolResult.fail('send_media_key', 'Unknown media key: $key');
    }
    try {
      final script = code == '{UP}' || code == '{DOWN}'
          ? '(new-object -com wscript.shell).SendKeys([char]174)'
          : '(new-object -com wscript.shell).SendKeys(\'$code\')';
      Process.runSync('powershell', ['-NoProfile', '-Command', script],
          runInShell: true);
      return ToolResult.ok('media_control', 'Media key sent: $key');
    } catch (e) {
      return ToolResult.fail('media_control', e.toString());
    }
  }

  ToolResult changeVolume(int percent) {
    try {
      // Set absolute volume 0-100 via nircmd-free PowerShell approach using
      // SendKeys on the volume mixer is unreliable; use keystrokes relative.
      final presses = (percent / 2).round(); // each VK 175 = +2%
      final key = presses > 50 ? [char]176 : [char]175;
      final count = presses > 50 ? presses : 100 - presses;
      Process.runSync('powershell', [
        '-NoProfile',
        '-Command',
        '''
\$shell = New-Object -ComObject WScript.Shell
1..\$count | ForEach-Object { \$shell.SendKeys([char]$key) }
'''.replaceAll(r'$count', count.toString()),
      ], runInShell: true);
      return ToolResult.ok('change_volume', 'Volume set to ~$percent%');
    } catch (e) {
      return ToolResult.fail('change_volume', e.toString());
    }
  }
}
