import 'dart:io';
import 'package:flutter/foundation.dart';

class SystemStats {
  final double cpuUsage;
  final double ramUsage;
  final double totalRamGb;
  final double usedRamGb;
  final int batteryLevel;
  final bool isCharging;
  final String osName;

  SystemStats({
    required this.cpuUsage,
    required this.ramUsage,
    required this.totalRamGb,
    required this.usedRamGb,
    required this.batteryLevel,
    required this.isCharging,
    required this.osName,
  });

  factory SystemStats.initial() {
    return SystemStats(
      cpuUsage: 18.0,
      ramUsage: 42.0,
      totalRamGb: 16.0,
      usedRamGb: 6.8,
      batteryLevel: 88,
      isCharging: true,
      osName: kIsWeb ? 'Web / Browser' : Platform.operatingSystem,
    );
  }

  Map<String, dynamic> toJson() => {
    'cpuUsage': cpuUsage,
    'ramUsage': ramUsage,
    'totalRamGb': totalRamGb,
    'usedRamGb': usedRamGb,
    'batteryLevel': batteryLevel,
    'isCharging': isCharging,
    'osName': osName,
  };
}

class SystemInfoUtil {
  static Future<SystemStats> getRealWindowsStats() async {
    if (kIsWeb || !Platform.isWindows) {
      return SystemStats.initial();
    }

    try {
      final script = '''
      \$os = Get-CimInstance Win32_OperatingSystem
      \$totalRam = [math]::Round(\$os.TotalVisibleMemorySize / 1MB, 1)
      \$freeRam = [math]::Round(\$os.FreePhysicalMemory / 1MB, 1)
      \$usedRam = [math]::Round(\$totalRam - \$freeRam, 1)
      \$ramPercent = [math]::Round((\$usedRam / \$totalRam) * 100, 1)

      \$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
      if (\$null -eq \$cpu) { \$cpu = 15 }

      \$battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
      \$batPct = if (\$battery) { \$battery.EstimatedChargeRemaining } else { 100 }
      \$isCharge = if (\$battery) { (\$battery.BatteryStatus -eq 2) } else { \$true }

      Write-Output "\$cpu|\$ramPercent|\$totalRam|\$usedRam|\$batPct|\$isCharge"
      ''';

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final parts = result.stdout.toString().trim().split('|');
        if (parts.length >= 6) {
          final cpu = double.tryParse(parts[0].trim()) ?? 20.0;
          final ramPct = double.tryParse(parts[1].trim()) ?? 45.0;
          final totalRam = double.tryParse(parts[2].trim()) ?? 16.0;
          final usedRam = double.tryParse(parts[3].trim()) ?? 7.2;
          final bat = int.tryParse(parts[4].trim()) ?? 90;
          final charge = parts[5].trim().toLowerCase() == 'true';

          return SystemStats(
            cpuUsage: cpu,
            ramUsage: ramPct,
            totalRamGb: totalRam,
            usedRamGb: usedRam,
            batteryLevel: bat,
            isCharging: charge,
            osName: 'Windows 11/10',
          );
        }
      }
    } catch (_) {}

    return SystemStats.initial();
  }
}
