import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider.dart';
import '../core/utils/logger.dart';

class LocalAIProvider implements BaseAIProvider {
  final String serverUrl;
  final String model;
  final Dio _dio;

  LocalAIProvider({
    this.serverUrl = 'http://127.0.0.1:11434',
    this.model = 'llama3',
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

  @override
  String get name => 'Local AI / Offline Heuristic';

  @override
  Future<AIResponse> sendMessage({
    required String prompt,
    required String systemPrompt,
    List<Map<String, dynamic>> conversationHistory = const [],
    bool enableTools = true,
  }) async {
    // 1. Try local Ollama / LLM HTTP endpoint if running
    try {
      final response = await _dio.post(
        '$serverUrl/api/generate',
        data: jsonEncode({
          'model': model,
          'prompt': '$systemPrompt\n\nUser: $prompt\nJARVIS:',
          'stream': false,
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final text = response.data['response'] as String? ?? '';
        final heuristicCalls = _detectToolsHeuristically(prompt);
        return AIResponse(
          text: text.isNotEmpty ? text.trim() : 'Buyruq qabul qilindi.',
          toolCalls: heuristicCalls,
        );
      }
    } catch (_) {
      // Local LLM server not reachable, use intelligent heuristic offline rule engine
    }

    // 2. Intelligent Offline Fallback Parser
    return _parseOfflineCommand(prompt);
  }

  AIResponse _parseOfflineCommand(String input) {
    final lower = input.toLowerCase().trim();
    final toolCalls = _detectToolsHeuristically(input);

    String speech = 'Albatta.';
    if (lower.contains('chrome') || lower.contains('brauzer')) {
      speech = 'Google Chrome ochilmoqda.';
    } else if (lower.contains('youtube')) {
      speech = 'YouTube ochilmoqda.';
    } else if (lower.contains('vscode') || lower.contains('vs code') || lower.contains('kod')) {
      speech = 'Visual Studio Code ochilmoqda.';
    } else if (lower.contains('ovoz') || lower.contains('volume') || lower.contains('musiqa')) {
      speech = 'Media buyrug‘i bajarilmoqda.';
    } else if (lower.contains('qulf') || lower.contains('lock')) {
      speech = 'Kompyuter qulflanmoqda.';
    } else if (lower.contains('bot') || lower.contains('telegram')) {
      speech = 'Telegram bot loyihasi tayyorlanmoqda.';
    } else if (lower.contains('salom') || lower.contains('qalaysan') || lower.contains('hello')) {
      speech = 'Salom! Men JARVIS. Sizga qanday yordam bera olaman?';
    } else {
      speech = 'Buyrug‘ingiz qabul qilindi va bajarilmoqda.';
    }

    return AIResponse(
      text: speech,
      toolCalls: toolCalls,
    );
  }

  List<AIToolCall> _detectToolsHeuristically(String input) {
    final lower = input.toLowerCase().trim();
    final calls = <AIToolCall>[];
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // YouTube search / play music
    if (lower.contains('youtube') || (lower.contains('musiqa') && (lower.contains('qo\'y') || lower.contains('qo‘y') || lower.contains('ijro') || lower.contains('top')))) {
      String query = 'music';
      if (lower.contains('m1nor') || lower.contains('minor')) {
        query = 'M1nor';
      } else if (lower.contains('youtube')) {
        final regex = RegExp(r'youtube(?:dan|da)?\s*(.+?)(?:ni|ni\s+qo|ni\s+top|ni\s+ijro|$)', caseSensitive: false);
        final match = regex.firstMatch(lower);
        if (match != null && match.group(1) != null && match.group(1)!.trim().isNotEmpty) {
          query = match.group(1)!.trim();
        }
      }
      calls.add(AIToolCall(
        id: id,
        name: 'browser_action',
        arguments: {'action': 'play_youtube', 'query': query},
      ));
    }
    // VS Code + Telegram bot creation
    else if ((lower.contains('bot') || lower.contains('telegram')) && (lower.contains('yarat') || lower.contains('yoz') || lower.contains('tuz'))) {
      calls.add(AIToolCall(
        id: id,
        name: 'create_code_project',
        arguments: {
          'project_name': 'JarvisTelegramBot',
          'project_type': 'python_telegram_bot',
          'custom_description': 'Telegram bot with aiogram',
          'open_in_vscode': true,
        },
      ));
    }
    // VS Code open
    else if (lower.contains('vs code') || lower.contains('vscode') || lower.contains('visual studio code') || lower.contains('kod muharrir')) {
      calls.add(AIToolCall(
        id: id,
        name: 'open_application',
        arguments: {'application_name': 'vscode'},
      ));
    }
    // Chrome open
    else if (lower.contains('chrome') || lower.contains('brauzer')) {
      calls.add(AIToolCall(
        id: id,
        name: 'open_application',
        arguments: {'application_name': 'chrome'},
      ));
    }
    // Telegram open
    else if (lower.contains('telegram') && !lower.contains('bot')) {
      calls.add(AIToolCall(
        id: id,
        name: 'open_application',
        arguments: {'application_name': 'telegram'},
      ));
    }
    // Notepad open
    else if (lower.contains('notepad') || lower.contains('bloknot')) {
      calls.add(AIToolCall(
        id: id,
        name: 'open_application',
        arguments: {'application_name': 'notepad'},
      ));
    }
    // Calculator
    else if (lower.contains('kalkulyator') || lower.contains('calculator') || lower.contains('calc')) {
      calls.add(AIToolCall(
        id: id,
        name: 'open_application',
        arguments: {'application_name': 'calc'},
      ));
    }
    // Volume / Media Controls
    else if (lower.contains('ovoz') || lower.contains('volume')) {
      if (lower.contains('oshir') || lower.contains('baland') || lower.contains('up')) {
        calls.add(AIToolCall(id: id, name: 'control_media', arguments: {'command': 'volume_up'}));
      } else if (lower.contains('tushir') || lower.contains('pasaytir') || lower.contains('down')) {
        calls.add(AIToolCall(id: id, name: 'control_media', arguments: {'command': 'volume_down'}));
      } else if (lower.contains('o\'chir') || lower.contains('ochir') || lower.contains('mute')) {
        calls.add(AIToolCall(id: id, name: 'control_media', arguments: {'command': 'mute'}));
      }
    }
    // Play/pause media
    else if (lower.contains('to\'xtat') || lower.contains('toxtat') || lower.contains('pause') || lower.contains('stop')) {
      calls.add(AIToolCall(id: id, name: 'control_media', arguments: {'command': 'play_pause'}));
    } else if (lower.contains('davom') || lower.contains('play') || lower.contains('resume')) {
      calls.add(AIToolCall(id: id, name: 'control_media', arguments: {'command': 'play_pause'}));
    } else if (lower.contains('keyingi') || lower.contains('next')) {
      calls.add(AIToolCall(id: id, name: 'control_media', arguments: {'command': 'next'}));
    }
    // Lock PC
    else if (lower.contains('qulf') || lower.contains('lock') || lower.contains('blokla')) {
      calls.add(AIToolCall(id: id, name: 'get_system_info', arguments: {'action': 'lock_pc'}));
    }
    // System diagnostics
    else if (lower.contains('tizim') || lower.contains('holat') || lower.contains('status') || lower.contains('cpu') || lower.contains('ram')) {
      calls.add(AIToolCall(id: id, name: 'get_system_info', arguments: {'action': 'get_status'}));
    }

    return calls;
  }
}
