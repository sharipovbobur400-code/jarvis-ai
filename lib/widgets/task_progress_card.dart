import 'package:flutter/material.dart';
import '../ai/task_planner.dart';
import '../core/config/theme.dart';

class TaskProgressCard extends StatelessWidget {
  final JarvisPlan plan;

  const TaskProgressCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: JarvisTheme.cardBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JarvisTheme.primaryCyan.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: JarvisTheme.primaryCyan.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, size: 20, color: JarvisTheme.primaryCyan),
                  const SizedBox(width: 8),
                  Text(
                    plan.taskTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: JarvisTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${plan.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: plan.progressPercentage / 100.0,
              backgroundColor: JarvisTheme.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(JarvisTheme.primaryCyan),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          ...plan.steps.map((step) => _buildStepRow(step)),
        ],
      ),
    );
  }

  Widget _buildStepRow(TaskStep step) {
    Widget iconWidget;
    Color textColor = JarvisTheme.textSecondary;

    switch (step.status) {
      case StepStatus.completed:
        iconWidget = const Icon(Icons.check_circle, size: 16, color: JarvisTheme.success);
        textColor = JarvisTheme.textPrimary;
        break;
      case StepStatus.inProgress:
        iconWidget = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(JarvisTheme.accentGold),
          ),
        );
        textColor = JarvisTheme.accentGold;
        break;
      case StepStatus.failed:
        iconWidget = const Icon(Icons.cancel, size: 16, color: JarvisTheme.danger);
        textColor = JarvisTheme.danger;
        break;
      case StepStatus.pending:
        iconWidget = const Icon(Icons.radio_button_unchecked, size: 14, color: JarvisTheme.textMuted);
        textColor = JarvisTheme.textMuted;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: step.status == StepStatus.inProgress ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
