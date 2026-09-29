import '../core/config/app_config.dart';
import '../core/config/constants.dart';
import '../core/storage/local_database.dart';

class PromptManager {
  static String buildSystemPrompt() {
    final config = AppConfig();
    final memories = LocalDatabaseService().getAllMemories();

    final memoryContext = memories.isEmpty
        ? 'No prior user memories recorded.'
        : memories.map((m) => '- ${m.key}: ${m.value}').join('\n');

    return '''
${JarvisConstants.systemPrompt}

User Configuration:
- Current User Name: ${config.userName}
- Preferred Language: ${config.language}
- Voice Gender: ${config.isFemaleVoice ? "Female" : "Male"}

Long-Term Context & Memories:
$memoryContext

Important Behavior:
- Always speak courteously to the user as ${config.userName}.
- When executing tools, keep spoken commentary concise (e.g. "Albatta. YouTube'ni ochyapman.").
- After executing tools, summarize the result succinctly.
''';
  }
}
