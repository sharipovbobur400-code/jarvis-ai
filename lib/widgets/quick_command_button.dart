import 'package:flutter/material.dart';
import '../core/config/theme.dart';

class QuickCommandButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const QuickCommandButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? JarvisTheme.primaryCyan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: activeColor.withOpacity(0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: JarvisTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JarvisTheme.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: activeColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: JarvisTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
