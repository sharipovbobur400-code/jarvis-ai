import 'package:flutter/material.dart';
import '../core/config/theme.dart';

class DangerConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String targetPathOrCommand;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DangerConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.targetPathOrCommand,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required String target,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DangerConfirmationDialog(
        title: title,
        description: description,
        targetPathOrCommand: target,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: JarvisTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: JarvisTheme.danger, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: JarvisTheme.danger, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: JarvisTheme.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(color: JarvisTheme.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: JarvisTheme.cardBorder),
              ),
              child: SelectableText(
                targetPathOrCommand,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  color: JarvisTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JarvisTheme.textMuted,
                    side: const BorderSide(color: JarvisTheme.cardBorder),
                  ),
                  child: const Text('Bekor qilish'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JarvisTheme.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tasdiqlash'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
