/// Permission categories (section 25). Every tool belongs to one; the
/// executor checks the user's enabled permissions before running it.
enum Permission { browser, files, terminal, applications, system, network }

/// Actions that always require explicit user confirmation (section 26).
class SafetyPolicy {
  static const dangerousPatterns = [
    'format',
    'del /s',
    'rmdir /s',
    'rd /s',
    'rm -rf',
    'shutdown',
    'restart',
    'reg add',
    'reg delete',
    'regedit',
    'netsh',
    'taskkill /f /im wininit',
    'cipher /w',
    'diskpart',
    'bcdedit',
    'vssadmin delete',
    'remove-item -recurse -force',
  ];

  static bool isDangerousCommand(String command) {
    final c = command.toLowerCase();
    return dangerousPatterns.any(c.contains);
  }

  static const confirmationHintsUz = {
    'delete': "Bu amal fayllarni o'chirishi mumkin. Davom etaymi?",
    'shutdown': "Kompyuter o'chishi mumkin. Davom etaymi?",
    'registry': "Bu amal tizim sozlamalariga ta'sir qilishi mumkin. Davom etaymi?",
  };
}
