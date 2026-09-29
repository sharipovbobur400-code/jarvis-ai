import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../../core/utils/system_info.dart';
import '../../ai/ai_service.dart';
import '../../ai/task_planner.dart';
import '../../voice/speech_to_text.dart';
import '../../voice/text_to_speech.dart';
import '../../voice/wake_word.dart';
import '../../tools/tool_registry.dart';
import '../../widgets/ai_core_visualizer.dart';
import '../../widgets/audio_waveform.dart';
import '../../widgets/system_stats_card.dart';
import '../../widgets/task_progress_card.dart';
import '../../widgets/quick_command_button.dart';

class HomeScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final STTService _stt = STTService();
  final TTSService _tts = TTSService();
  final AIService _ai = AIService();
  final TaskPlanner _planner = TaskPlanner();

  String _statusText = '"Sizga qanday yordam beray?"';
  String _recognizedWords = '';
  double _soundLevel = 0.0;
  bool _isProcessing = false;
  SystemStats _systemStats = SystemStats.initial();
  Timer? _statsTimer;
  JarvisPlan? _activePlan;

  @override
  void initState() {
    super.initState();
    _initVoiceAndStats();
  }

  void _initVoiceAndStats() async {
    await _tts.init();
    await _stt.init();

    _stt.onResult = (words, isFinal) {
      setState(() {
        _recognizedWords = words;
        _statusText = words;
      });

      if (isFinal && words.isNotEmpty) {
        _handleUserInput(words);
      }
    };

    _stt.onSoundLevelChange = (level) {
      if (mounted) {
        setState(() => _soundLevel = level);
      }
    };

    _stt.onListeningStateChanged = (isListening) {
      if (mounted) {
        setState(() {
          if (isListening) {
            _statusText = 'Tinglayapman...';
          }
        });
      }
    };

    _tts.onSpeakingChanged = (speaking) {
      if (mounted) setState(() {});
    };

    // Load initial system stats & refresh every 5 seconds
    _refreshStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshStats());
  }

  void _refreshStats() async {
    final stats = await SystemInfoUtil.getRealWindowsStats();
    if (mounted) {
      setState(() => _systemStats = stats);
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  void _toggleListening() async {
    if (_stt.isListening) {
      await _stt.stopListening();
      if (_recognizedWords.isNotEmpty) {
        _handleUserInput(_recognizedWords);
      }
    } else {
      await _tts.stop();
      setState(() {
        _recognizedWords = '';
        _statusText = 'Eshitaman...';
      });
      await _stt.startListening();
    }
  }

  void _handleUserInput(String input) async {
    if (input.trim().isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Buyruq qayta ishlanmoqda...';
    });

    final cleanedInput = WakeWordDetector.stripWakeWord(input);
    final targetCommand = cleanedInput.isNotEmpty ? cleanedInput : input;

    final response = await _ai.processUserCommand(
      targetCommand,
      onStatusUpdate: (status) {
        if (mounted) {
          setState(() => _statusText = status);
        }
      },
      onPlanUpdate: (plan) {
        if (mounted) {
          setState(() => _activePlan = plan);
        }
      },
    );

    if (mounted) {
      setState(() {
        _statusText = response;
        _isProcessing = false;
      });
    }

    // Speak response in female JARVIS voice
    await _tts.speak(response);
  }

  void _executeQuickCommand(String command) {
    _handleUserInput(command);
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header with Title & Active Model
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'J A R V I S',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: JarvisTheme.primaryCyan,
                        ),
                      ),
                      Text(
                        'Salom, ${config.userName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: JarvisTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: JarvisTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: JarvisTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: JarvisTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          config.currentProvider.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: JarvisTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Animated Glowing AI Arc Reactor Core
              AICoreVisualizer(
                isListening: _stt.isListening,
                isSpeaking: _tts.isSpeaking,
                soundLevel: _soundLevel,
                size: 210,
              ),

              const SizedBox(height: 20),

              // Audio Waveform Visualizer
              AudioWaveform(
                isActive: _stt.isListening || _tts.isSpeaking || _isProcessing,
              ),

              const SizedBox(height: 16),

              // Dynamic Status & Spoken text
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: JarvisTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),

              // Active Multi-step Plan Card if running
              if (_activePlan != null && !_activePlan!.isCompleted)
                Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: TaskProgressCard(plan: _activePlan!),
                ),

              const Spacer(flex: 1),

              // Voice Action Button (Microphone)
              Center(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _stt.isListening
                          ? JarvisTheme.primaryCyan
                          : JarvisTheme.primaryCyan.withOpacity(0.15),
                      border: Border.all(
                        color: JarvisTheme.primaryCyan,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _stt.isListening
                              ? JarvisTheme.primaryCyan.withOpacity(0.6)
                              : JarvisTheme.primaryCyan.withOpacity(0.2),
                          blurRadius: _stt.isListening ? 20 : 8,
                          spreadRadius: _stt.isListening ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _stt.isListening ? Icons.mic : Icons.mic_none,
                      size: 32,
                      color: _stt.isListening ? Colors.black : JarvisTheme.primaryCyan,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QuickCommandButton(
                      label: 'Chrome',
                      icon: Icons.public,
                      onTap: () => _executeQuickCommand('Google Chrome brauzerini och'),
                    ),
                    const SizedBox(width: 8),
                    QuickCommandButton(
                      label: 'YouTube',
                      icon: Icons.play_circle_fill,
                      onTap: () => _executeQuickCommand('YouTube och va M1nor musiqasini qidir'),
                    ),
                    const SizedBox(width: 8),
                    QuickCommandButton(
                      label: 'VS Code',
                      icon: Icons.code,
                      onTap: () => _executeQuickCommand('Visual Studio Code och'),
                    ),
                    const SizedBox(width: 8),
                    QuickCommandButton(
                      label: 'Telegram Bot',
                      icon: Icons.smart_toy,
                      onTap: () => _executeQuickCommand('Python aiogram Telegram bot yarat va VS Code da och'),
                    ),
                    const SizedBox(width: 8),
                    QuickCommandButton(
                      label: 'Musiqa',
                      icon: Icons.music_note,
                      onTap: () => _executeQuickCommand('Musiqani davom ettir yoki toxtat'),
                    ),
                    const SizedBox(width: 8),
                    QuickCommandButton(
                      label: 'Lock PC',
                      icon: Icons.lock,
                      color: JarvisTheme.danger,
                      onTap: () => _executeQuickCommand('Kompyuterni qulfla'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Real-time System Diagnostics HUD
              SystemStatsCard(stats: _systemStats),
            ],
          ),
        ),
      ),
    );
  }
}
