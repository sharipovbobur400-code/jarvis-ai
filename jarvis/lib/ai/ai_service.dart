import 'ai_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/openai_provider.dart';
import '../core/config/app_config.dart';

/// Creates the configured provider; falls back gracefully and supports
/// swapping providers at runtime (section 4 / section 31).
class AiService {
  final AppConfig _config = AppConfig.instance;
  AiProvider? _provider;

  AiProvider get provider {
    if (_provider != null) return _provider!;
    final key = _config.aiApiKey;
    if (!_config.hasAiKey) {
      throw AiException(
          "AI kalit sozlanmagan. Sozlamalar bo'limida API kalitni kiriting.");
    }
    switch (_config.aiProvider.toLowerCase()) {
      case 'openai':
        _provider = OpenAiProvider(apiKey: key, model: _config.aiModel);
        break;
      case 'gemini':
      default:
        _provider = GeminiProvider(apiKey: key, model: _config.aiModel);
    }
    return _provider!;
  }

  void switchProvider(AiProvider p) => _provider = p;

  bool get isConfigured => _config.hasAiKey;
}
