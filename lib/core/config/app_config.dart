import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import 'constants.dart';

enum AIProviderType { gemini, openai, anthropic, local }

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  late SharedPreferences _prefs;
  final SecureStorageService _secureStorage = SecureStorageService();

  AIProviderType currentProvider = AIProviderType.gemini;
  String userName = JarvisConstants.defaultUserName;
  String language = JarvisConstants.defaultLanguage;
  double speechRate = 0.9;
  double speechPitch = 1.2;
  bool isFemaleVoice = true;
  bool autoExecuteSafeTools = true;
  int remoteServerPort = 8888;
  String localAiUrl = 'http://127.0.0.1:11434';

  // API Keys (securely cached in-memory during app runtime)
  String? geminiApiKey;
  String? openaiApiKey;
  String? anthropicApiKey;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    userName = _prefs.getString('user_name') ?? JarvisConstants.defaultUserName;
    language = _prefs.getString('language') ?? JarvisConstants.defaultLanguage;
    speechRate = _prefs.getDouble('speech_rate') ?? 0.9;
    speechPitch = _prefs.getDouble('speech_pitch') ?? 1.2;
    isFemaleVoice = _prefs.getBool('is_female_voice') ?? true;
    autoExecuteSafeTools = _prefs.getBool('auto_execute_safe_tools') ?? true;
    remoteServerPort = _prefs.getInt('remote_server_port') ?? 8888;
    localAiUrl = _prefs.getString('local_ai_url') ?? 'http://127.0.0.1:11434';

    final providerStr = _prefs.getString('ai_provider') ?? 'gemini';
    currentProvider = AIProviderType.values.firstWhere(
      (e) => e.name == providerStr,
      orElse: () => AIProviderType.gemini,
    );

    // Load API keys securely
    geminiApiKey = await _secureStorage.read('gemini_api_key');
    openaiApiKey = await _secureStorage.read('openai_api_key');
    anthropicApiKey = await _secureStorage.read('anthropic_api_key');
  }

  Future<void> setUserName(String name) async {
    userName = name;
    await _prefs.setString('user_name', name);
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
    await _prefs.setString('language', lang);
  }

  Future<void> setProvider(AIProviderType provider) async {
    currentProvider = provider;
    await _prefs.setString('ai_provider', provider.name);
  }

  Future<void> setGeminiApiKey(String key) async {
    geminiApiKey = key;
    await _secureStorage.write('gemini_api_key', key);
  }

  Future<void> setOpenAiApiKey(String key) async {
    openaiApiKey = key;
    await _secureStorage.write('openai_api_key', key);
  }

  Future<void> setAnthropicApiKey(String key) async {
    anthropicApiKey = key;
    await _secureStorage.write('anthropic_api_key', key);
  }

  Future<void> setLocalAiUrl(String url) async {
    localAiUrl = url;
    await _prefs.setString('local_ai_url', url);
  }

  Future<void> setVoiceSettings({
    required double rate,
    required double pitch,
    required bool female,
  }) async {
    speechRate = rate;
    speechPitch = pitch;
    isFemaleVoice = female;
    await _prefs.setDouble('speech_rate', rate);
    await _prefs.setDouble('speech_pitch', pitch);
    await _prefs.setBool('is_female_voice', female);
  }
}
