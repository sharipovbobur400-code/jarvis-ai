import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../ai/task_planner.dart';
import '../../widgets/task_progress_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskPlanner _planner = TaskPlanner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VAZIFALAR & REJALAR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktiv va Oxirgi Rejalar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: JarvisTheme.primaryCyan,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<JarvisPlan?>(
                stream: _planner.planStream,
                initialData: _planner.currentPlan,
                builder: (context, snapshot) {
                  final plan = snapshot.data;
                  if (plan == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist_rtl_rounded, size: 48, color: JarvisTheme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Hozirda faol ko‘p bosqichli vazifa yo‘q.\n"JARVIS, Telegram bot yarat va VS Code da och" deb buyruq bering.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: JarvisTheme.textMuted),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    children: [
                      TaskProgressCard(plan: plan),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
