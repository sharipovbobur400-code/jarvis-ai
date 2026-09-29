import 'package:flutter/material.dart';
import '../core/config/theme.dart';
import '../core/utils/system_info.dart';

class SystemStatsCard extends StatelessWidget {
  final SystemStats stats;

  const SystemStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: JarvisTheme.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JarvisTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('CPU', '${stats.cpuUsage.toStringAsFixed(0)}%', Icons.memory, JarvisTheme.primaryCyan),
          _buildDivider(),
          _buildStatItem('RAM', '${stats.ramUsage.toStringAsFixed(0)}%', Icons.storage, JarvisTheme.accentGold),
          _buildDivider(),
          _buildStatItem('BAT', '${stats.batteryLevel}%', stats.isCharging ? Icons.battery_charging_full : Icons.battery_std, JarvisTheme.success),
          _buildDivider(),
          _buildStatItem('OS', stats.osName, Icons.desktop_windows, JarvisTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: JarvisTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: JarvisTheme.cardBorder,
    );
  }
}
