import 'dart:io';
import '../core/security/safety_policy.dart';
import 'tool_result.dart';

/// Runs terminal commands on Windows with a safety gate (sections 15, 26).
class TerminalTool {
  /// Returns true when the command requires explicit confirmation.
  bool requiresConfirmation(String command) =>
      SafetyPolicy.isDangerousCommand(command);

  Future<ToolResult> run(String command,
      {required bool confirmed, String? workingDir}) async {
    if (requiresConfirmation(command) && !confirmed) {
      return ToolResult(
        success: false,
        tool: 'run_terminal_command',
        error: 'confirmation_required',
        message: SafetyPolicy.confirmationHintsUz['delete'],
        data: {'command': command, 'needsConfirmation': true},
      );
    }
    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-Command', command],
        runInShell: true,
        workingDirectory: workingDir,
        stdoutEncoding: utf8WithCyrillicFallback(),
        stderrEncoding: utf8WithCyrillicFallback(),
      );
      final out = ((result.stdout ?? '') as String).trim();
      final err = ((result.stderr ?? '') as String).trim();
      final ok = result.exitCode == 0;
      return ToolResult(
        success: ok,
        tool: 'run_terminal_command',
        message: out.isEmpty ? null : out,
        error: ok ? null : (err.isEmpty ? 'Exit code ${result.exitCode}' : err),
        data: {'command': command, 'exitCode': result.exitCode},
      );
    } catch (e) {
      return ToolResult.fail('run_terminal_command', e.toString());
    }
  }
}

/// PowerShell console output is often OEM-encoded; use system encoding with
/// UTF-8 preference so Cyrillic/UTF-8 output is readable.
Encoding utf8WithCyrillicFallback() => const SystemEncoding();
