import 'dart:async';
import '../tools/base_tool.dart';
import '../tools/tool_registry.dart';
import '../core/utils/logger.dart';

enum StepStatus { pending, inProgress, completed, failed }

class TaskStep {
  final int id;
  final String title;
  final String toolName;
  final Map<String, dynamic> arguments;
  StepStatus status;
  String? resultMessage;

  TaskStep({
    required this.id,
    required this.title,
    required this.toolName,
    required this.arguments,
    this.status = StepStatus.pending,
    this.resultMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'toolName': toolName,
    'arguments': arguments,
    'status': status.name,
    'resultMessage': resultMessage,
  };
}

class JarvisPlan {
  final String taskTitle;
  final List<TaskStep> steps;
  bool isCompleted;
  bool isFailed;

  JarvisPlan({
    required this.taskTitle,
    required this.steps,
    this.isCompleted = false,
    this.isFailed = false,
  });

  double get progressPercentage {
    if (steps.isEmpty) return 0.0;
    final completed = steps.where((s) => s.status == StepStatus.completed).length;
    return (completed / steps.length) * 100.0;
  }
}

class TaskPlanner {
  static final TaskPlanner _instance = TaskPlanner._internal();
  factory TaskPlanner() => _instance;
  TaskPlanner._internal();

  JarvisPlan? currentPlan;
  final StreamController<JarvisPlan?> _planController = StreamController<JarvisPlan?>.broadcast();
  Stream<JarvisPlan?> get planStream => _planController.stream;

  JarvisPlan createPlanFromIntent(String intent) {
    final lower = intent.toLowerCase();
    final steps = <TaskStep>[];

    if (lower.contains('telegram bot') || (lower.contains('bot') && lower.contains('vs code'))) {
      steps.add(TaskStep(
        id: 1,
        title: 'Project directory yaratish',
        toolName: 'file_operations',
        arguments: {'operation': 'create_folder', 'path': 'Desktop/JarvisTelegramBot'},
      ));
      steps.add(TaskStep(
        id: 2,
        title: 'main.py va bot kodini yaratish',
        toolName: 'create_code_project',
        arguments: {
          'project_name': 'JarvisTelegramBot',
          'project_type': 'python_telegram_bot',
          'open_in_vscode': false,
        },
      ));
      steps.add(TaskStep(
        id: 3,
        title: 'requirements.txt va dependencylarni tekshirish',
        toolName: 'file_operations',
        arguments: {'operation': 'read_file', 'path': 'Desktop/JarvisTelegramBot/requirements.txt'},
      ));
      steps.add(TaskStep(
        id: 4,
        title: 'VS Code ochish va loyihani yuklash',
        toolName: 'open_application',
        arguments: {'application_name': 'vscode', 'arguments': 'Desktop/JarvisTelegramBot'},
      ));
      return JarvisPlan(taskTitle: 'Telegram Bot yaratish va VS Code\'da ochish', steps: steps);
    } else if (lower.contains('chrome') && lower.contains('youtube')) {
      steps.add(TaskStep(
        id: 1,
        title: 'Google Chrome brauzerini ochish',
        toolName: 'open_application',
        arguments: {'application_name': 'chrome'},
      ));
      steps.add(TaskStep(
        id: 2,
        title: 'YouTube orqali musiqani izlash va ijro etish',
        toolName: 'browser_action',
        arguments: {'action': 'play_youtube', 'query': 'M1nor'},
      ));
      return JarvisPlan(taskTitle: 'Chrome va YouTube Musiqa Ijrosi', steps: steps);
    }

    // Default single-action plan
    return JarvisPlan(taskTitle: 'Buyruqni bajarish', steps: steps);
  }

  Future<bool> executePlan(JarvisPlan plan, {Function(TaskStep step)? onStepUpdate}) async {
    currentPlan = plan;
    _planController.add(currentPlan);

    for (var step in plan.steps) {
      step.status = StepStatus.inProgress;
      _planController.add(currentPlan);
      onStepUpdate?.call(step);

      JarvisLogger.info('Executing Plan Step [${step.id}/${plan.steps.length}]: ${step.title}');

      final result = await ToolRegistry().execute(step.toolName, step.arguments);

      if (result.success) {
        step.status = StepStatus.completed;
        step.resultMessage = result.message;
      } else {
        step.status = StepStatus.failed;
        step.resultMessage = result.error;
        plan.isFailed = true;
        _planController.add(currentPlan);
        onStepUpdate?.call(step);
        return false;
      }

      _planController.add(currentPlan);
      onStepUpdate?.call(step);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    plan.isCompleted = true;
    _planController.add(currentPlan);
    return true;
  }

  void clearPlan() {
    currentPlan = null;
    _planController.add(null);
  }
}
