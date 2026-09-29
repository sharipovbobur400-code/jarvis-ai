import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/tools/tool_registry.dart';
import 'package:jarvis_ai/core/security/security_guard.dart';
import 'package:jarvis_ai/ai/task_planner.dart';
import 'package:jarvis_ai/voice/wake_word.dart';

void main() {
  group('JARVIS Core & Tools Tests', () {
    test('ToolRegistry contains all required tools', () {
      final registry = ToolRegistry();
      final tools = registry.getAllTools();
      final toolNames = tools.map((t) => t.name).toList();

      expect(toolNames, contains('open_application'));
      expect(toolNames, contains('browser_action'));
      expect(toolNames, contains('control_media'));
      expect(toolNames, contains('file_operations'));
      expect(toolNames, contains('run_terminal_command'));
      expect(toolNames, contains('create_code_project'));
      expect(toolNames, contains('get_system_info'));
    });

    test('SecurityGuard detects high risk commands correctly', () {
      final guard = SecurityGuard();
      expect(guard.assessTerminalCommand('rm -rf /'), equals(RiskLevel.high));
      expect(guard.assessTerminalCommand('shutdown /s /t 0'), equals(RiskLevel.high));
      expect(guard.assessTerminalCommand('format d:'), equals(RiskLevel.high));
      expect(guard.assessTerminalCommand('python --version'), equals(RiskLevel.safe));
      expect(guard.assessTerminalCommand('pip list'), equals(RiskLevel.safe));
    });

    test('WakeWordDetector recognizes JARVIS wake words', () {
      expect(WakeWordDetector.containsWakeWord('Hey JARVIS, open chrome'), isTrue);
      expect(WakeWordDetector.containsWakeWord('Salom JARVIS, musiqa qo\'y'), isTrue);
      expect(WakeWordDetector.containsWakeWord('JARVIS, python bot yarat'), isTrue);
      expect(WakeWordDetector.containsWakeWord('Oddiy matn'), isFalse);

      final stripped = WakeWordDetector.stripWakeWord('Hey JARVIS, Chrome och');
      expect(stripped.toLowerCase(), contains('chrome och'));
    });

    test('TaskPlanner builds multi-step plan for Telegram bot creation', () {
      final planner = TaskPlanner();
      final plan = planner.createPlanFromIntent('JARVIS, Telegram bot yarat va VS Code da och');

      expect(plan.steps.isNotEmpty, isTrue);
      expect(plan.steps.length, greaterThanOrEqualTo(3));
      expect(plan.taskTitle, contains('Telegram Bot'));
    });
  });
}
