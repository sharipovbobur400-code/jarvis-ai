enum ToolCategory {
  application,
  browser,
  fileRead,
  fileWrite,
  fileDelete,
  terminal,
  media,
  system,
  network,
}

enum RiskLevel {
  safe,      // Can execute automatically
  moderate,  // Low impact (e.g. creating a temporary file)
  high,      // Dangerous (deleting files, terminal execution, system shutdown)
}

class SecurityGuard {
  static final SecurityGuard _instance = SecurityGuard._internal();
  factory SecurityGuard() => _instance;
  SecurityGuard._internal();

  // Dangerous keywords that mandate user confirmation
  static const List<String> dangerousTerminalKeywords = [
    'rm -rf',
    'del /s',
    'rd /s',
    'format ',
    'diskpart',
    'shutdown',
    'reg add',
    'reg delete',
    'drop database',
    'net user',
    'netsh firewall',
    'stop-process',
    'taskkill /f',
    'set-executionpolicy',
  ];

  RiskLevel assessTerminalCommand(String command) {
    final lower = command.toLowerCase().trim();
    for (var keyword in dangerousTerminalKeywords) {
      if (lower.contains(keyword)) {
        return RiskLevel.high;
      }
    }
    return RiskLevel.safe;
  }

  RiskLevel assessFileOperation(String operation, String path) {
    if (operation.toLowerCase().contains('delete') || operation.toLowerCase().contains('remove')) {
      return RiskLevel.high;
    }
    // Check if path is in Windows System directory
    final lowerPath = path.toLowerCase();
    if (lowerPath.contains('c:\\windows') || lowerPath.contains('c:\\program files')) {
      return RiskLevel.high;
    }
    return RiskLevel.safe;
  }

  RiskLevel assessSystemAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('shutdown') || lower.contains('restart') || lower.contains('sleep') || lower.contains('lock')) {
      return RiskLevel.high;
    }
    return RiskLevel.safe;
  }
}
