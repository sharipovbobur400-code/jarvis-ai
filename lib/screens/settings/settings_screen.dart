import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../../voice/text_to_speech.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppConfig _config = AppConfig();
  final TTSService _tts = TTSService();

  late TextEditingController _userNameController;
  late TextEditingController _geminiKeyController;
  late TextEditingController _openAiKeyController;
  late TextEditingController _anthropicKeyController;
  late TextEditingController _localAiUrlController;

  AIProviderType _selectedProvider = AIProviderType.gemini;
  String _selectedLanguage = 'uz-UZ';
  double _speechRate = 0.9;
  double _speechPitch = 1.2;
  bool _isFemaleVoice = true;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: _config.userName);
    _geminiKeyController = TextEditingController(text: _config.geminiApiKey ?? '');
    _openAiKeyController = TextEditingController(text: _config.openaiApiKey ?? '');
    _anthropicKeyController = TextEditingController(text: _config.anthropicApiKey ?? '');
    _localAiUrlController = TextEditingController(text: _config.localAiUrl);

    _selectedProvider = _config.currentProvider;
    _selectedLanguage = _config.language;
    _speechRate = _config.speechRate;
    _speechPitch = _config.speechPitch;
    _isFemaleVoice = _config.isFemaleVoice;
  }

  void _saveSettings() async {
    await _config.setUserName(_userNameController.text.trim());
    await _config.setProvider(_selectedProvider);
    await _config.setLanguage(_selectedLanguage);
    await _config.setGeminiApiKey(_geminiKeyController.text.trim());
    await _config.setOpenAiApiKey(_openAiKeyController.text.trim());
    await _config.setAnthropicApiKey(_anthropicKeyController.text.trim());
    await _config.setLocalAiUrl(_localAiUrlController.text.trim());
    await _config.setVoiceSettings(
      rate: _speechRate,
      pitch: _speechPitch,
      female: _isFemaleVoice,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sozlamalar saqlandi!'),
          backgroundColor: JarvisTheme.success,
        ),
      );
    }

    await _tts.speak('Sozlamalar muvaffaqiyatli saqlandi.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS SOZLAMALARI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: JarvisTheme.primaryCyan),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI PROVIDER SECTION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Provider (Sun\'iy Intellekt Miyasi)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JarvisTheme.primaryCyan),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AIProviderType>(
                      value: _selectedProvider,
                      dropdownColor: JarvisTheme.cardBackground,
                      decoration: const InputDecoration(labelText: 'Asosiy AI Model'),
                      items: const [
                        DropdownMenuItem(
                          value: AIProviderType.gemini,
                          child: Text('Google Gemini 1.5 Flash (Tavsiya etiladi)'),
                        ),
                        DropdownMenuItem(
                          value: AIProviderType.openai,
                          child: Text('OpenAI GPT-4o Mini'),
                        ),
                        DropdownMenuItem(
                          value: AIProviderType.anthropic,
                          child: Text('Anthropic Claude 3.5'),
                        ),
                        DropdownMenuItem(
                          value: AIProviderType.local,
                          child: Text('Lokal AI / Offline Heuristic'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProvider = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _geminiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _openAiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'OpenAI API Key (Ixtiyoriy)',
                        hintText: 'sk-...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _anthropicKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Anthropic Claude API Key (Ixtiyoriy)',
                        hintText: 'sk-ant-...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _localAiUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Lokal AI / Ollama URL',
                        hintText: 'http://127.0.0.1:11434',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // USER PERSONALITY SECTION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foydalanuvchi & Ovoz Sozlamalari',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JarvisTheme.accentGold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: 'Foydalanuvchi ismi',
                        hintText: 'Bobur',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      dropdownColor: JarvisTheme.cardBackground,
                      decoration: const InputDecoration(labelText: 'Til'),
                      items: const [
                        DropdownMenuItem(value: 'uz-UZ', child: Text('O‘zbekcha (uz-UZ)')),
                        DropdownMenuItem(value: 'ru-RU', child: Text('Русский (ru-RU)')),
                        DropdownMenuItem(value: 'en-US', child: Text('English (en-US)')),
                        DropdownMenuItem(value: 'ja-JP', child: Text('日本語 (ja-JP)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Qiz bola ovozi (Female AI Voice)'),
                      subtitle: const Text('Yandex Alice kabi yoqimli female audio ohang'),
                      value: _isFemaleVoice,
                      activeColor: JarvisTheme.primaryCyan,
                      onChanged: (val) => setState(() => _isFemaleVoice = val),
                    ),
                    const SizedBox(height: 8),
                    Text('Ovoz tezligi: ${_speechRate.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
                    Slider(
                      value: _speechRate,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      activeColor: JarvisTheme.primaryCyan,
                      onChanged: (val) => setState(() => _speechRate = val),
                    ),
                    Text('Ovoz balandligi (Pitch): ${_speechPitch.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
                    Slider(
                      value: _speechPitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      activeColor: JarvisTheme.accentGold,
                      onChanged: (val) => setState(() => _speechPitch = val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Barcha Sozlamalarni Saqlash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JarvisTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
