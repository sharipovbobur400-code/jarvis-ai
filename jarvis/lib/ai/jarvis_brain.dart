import 'dart:convert';
import '../tools/tool_executor.dart';
import '../tools/tool_result.dart';
import '../core/security/safety_policy.dart';
import 'ai_service.dart';
import 'memory_manager.dart';
import 'prompt_manager.dart';

/// Single conversation turn result.
class JarvisReply {
  final String speech;          // what JARVIS says (goes to TTS)
  final List<TaskStep>? steps;  // when a multi-step task ran / was planned
  final bool needsConfirmation;
  final String? pendingAction;
  final Map<String, dynamic>? pendingArgs;
  final List<String>? suggestions;

  JarvisReply({
    required this.speech,
    this.steps,
    this.needsConfirmation = false,
    this.pendingAction,
    this.pendingArgs,
    this.suggestions,
  });
}

class TaskStep {
  String title;
  StepStatus status;
  TaskStep(this.title, [this.status = StepStatus.pending]);
  Map<String, dynamic> toJson() =>
      {'title': title, 'status': status.name};
}

enum StepStatus { pending, running, done, failed }

extension _StepIcon on StepStatus {
  String get icon => switch (this) {
        StepStatus.done => '✓',
        StepStatus.running => '●',
        StepStatus.failed => '✗',
        StepStatus.pending => '○',
      };
}

/// The JARVIS brain: conversation memory + AI + tool dispatch + task planner.
class JarvisBrain {
  final AiService _ai = AiService();
  final MemoryManager memory = MemoryManager();
  final ToolExecutor tools = ToolExecutor();

  bool _awaitingConfirmation = false;
  String? _pendingAction;
  Map<String, dynamic>? _pendingArgs;

  /// Main entry: user text -> JARVIS reply (speech + optional executed steps).
  Future<JarvisReply> handle(String userText,
      {required Function(String) onStatus}) async {
    final userName = await memory.getProfile('name');
    final facts = await memory.facts();
    final history = await memory.recentMessages(limit: 16);

    final system = StringBuffer(PromptManager.systemPrompt);
    if (userName != null) {
      system.write("\nUser's name: $userName.");
    }
    if (facts.isNotEmpty) {
      system.write('\nRemembered facts:\n${facts.take(10).join('\n')}');
    }

    // Confirmation flow (section 26)
    if (_awaitingConfirmation) {
      final yes = _isYes(userText);
      _awaitingConfirmation = false;
      final action = _pendingAction ?? '';
      final args = _pendingArgs ?? {};
      _pendingAction = null;
      _pendingArgs = null;
      if (yes) {
        onStatus('Bajarilyapti...');
        final result = await tools.execute(action, args, confirmed: true);
        return JarvisReply(
          speech: result.success
              ? 'Bajarildi. ${result.message ?? ''}'
              : "Kechirasiz, bajara olmadim. ${result.error ?? ''}",
        );
      }
      return const JarvisReply(speech: 'Bekor qilindi.');
    }

    await memory.addMessage('user', userText);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system.toString()},
      ...history,
      {'role': 'user', 'content': userText},
    ];

    String raw;
    try {
      raw = await _ai.provider
          .chatWithTools(messages, PromptManager.toolInstruction(tools.toolCatalog));
    } catch (e) {
      // Offline fallback (section 31): local command routing without AI.
      final local = _localFallback(userText);
      await memory.addMessage('assistant', local.speech);
      return local;
    }

    final decision = _parseDecision(raw);
    await memory.addMessage('assistant', decision.speech);

    if (decision.action == null) {
      return JarvisReply(speech: decision.speech);
    }

    if (decision.action == 'confirm_required') {
      _awaitingConfirmation = true;
      return JarvisReply(speech: decision.speech, needsConfirmation: true);
    }

    // Destructive tools need confirmation even if AI forgot to ask.
    final args = decision.args;
    final cmd = '${args['command'] ?? ''}';
    final destructive = SafetyPolicy.isDangerousCommand(cmd) ||
        decision.action == 'delete_path';
    if (destructive) {
      _awaitingConfirmation = true;
      _pendingAction = decision.action;
      _pendingArgs = args;
      return JarvisReply(
        speech: "Bu amal tizimga ta'sir qilishi mumkin. Davom etaymi?",
        needsConfirmation: true,
      );
    }

    // Execute the tool and report honestly (section 30, 35).
    onStatus(decision.speech);
    final result = await tools.execute(decision.action, args, confirmed: false);

    final speech = result.success
        ? (decision.speech.isNotEmpty ? decision.speech : result.message ?? 'Bajarildi.')
        : _errorRecovery(decision.action, result);

    await memory.addMessage('assistant', speech);
    return JarvisReply(speech: speech);
  }

  /// Local command routing when the AI is unreachable (offline mode).
  JarvisReply _localFallback(String text) {
    final t = text.toLowerCase();
    if (t.contains('vaqt') || t.contains('soat') || t.contains('time')) {
      return JarvisReply(speech: tools.system.getTime().message ?? '');
    }
    if (t.contains('chrome')) {
      tools.execute('open_browser', {}, confirmed: false);
      return const JarvisReply(speech: "Chrome'ni ochdim.");
    }
    if (t.contains('youtube')) {
      tools.execute('open_youtube', {}, confirmed: false);
      return const JarvisReply(speech: "YouTube'ni ochdim.");
    }
    if (t.contains('volume') || t.contains('ovoz')) {
      return const JarvisReply(
          speech: "Internet yo'q, ovozni keyinroq boshqara olaman.");
    }
    return const JarvisReply(
      speech:
          "Internet yo'q, lekin dasturlarni ochish va vaqtni aytish kabi "
          "local buyruqlarni bajarishim mumkin.",
    );
  }

  String _errorRecovery(String action, ToolResult result) {
    if (action == 'open_application' && result.error == null) {
      final installed = tools.application.listInstalledApplications();
      if (installed.isNotEmpty) {
        return "Dastur topilmadi. O'rnatilgan dasturlar ro'yxatida "
            '${installed.take(5).join(', ')} bor. Qaysi birini ochay?';
      }
    }
    return "Kechirasiz, bajarib bo'lmadi. ${result.error ?? ''}";
  }

  bool _isYes(String t) {
    final l = t.toLowerCase().trim();
    return l == 'ha' || l.contains('ha,') || l == 'да' ||
        l == 'yes' || l.contains('tasdiql') || l == 'ok';
  }

  ({String? action, Map<String, dynamic> args, String speech}) _parseDecision(
      String raw) {
    final text = raw.trim();
    // Try to find a JSON object in the reply.
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        final json = jsonDecode(text.substring(start, end + 1));
        if (json is Map) {
          return (
            action: json['action'] as String?,
            args: (json['args'] as Map?)?.cast<String, dynamic>() ?? {},
            speech: (json['say'] as String?) ?? '',
          );
        }
      } catch (_) {}
    }
    return (action: null, args: <String, dynamic>{}, speech: text);
  }
}
