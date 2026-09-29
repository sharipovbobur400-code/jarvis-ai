import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../core/storage/local_database.dart';
import '../../ai/ai_service.dart';
import '../../voice/text_to_speech.dart';

class BrainScreen extends StatefulWidget {
  const BrainScreen({super.key});

  @override
  State<BrainScreen> createState() => _BrainScreenState();
}

class _BrainScreenState extends State<BrainScreen> {
  final LocalDatabaseService _db = LocalDatabaseService();
  final AIService _ai = AIService();
  final TTSService _tts = TTSService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ConversationMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      _messages = _db.getRecentMessages(50);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _isLoading = true;
      _messages.add(ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    final response = await _ai.processUserCommand(text);

    setState(() {
      _isLoading = false;
      _messages.add(ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    await _tts.speak(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI MIYA / CHAT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: JarvisTheme.textMuted),
            tooltip: 'Tarixni tozalash',
            onPressed: () async {
              await _db.clearHistory();
              _loadMessages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Hozircha suhbat mavjud emas.\nBiror buyruq yozing yoki mikrofondan foydalaning.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: JarvisTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? JarvisTheme.primaryCyan.withOpacity(0.15)
                                : JarvisTheme.cardBackground,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                            border: Border.all(
                              color: isUser
                                  ? JarvisTheme.primaryCyan.withOpacity(0.4)
                                  : JarvisTheme.cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUser ? Icons.person : Icons.smart_toy_outlined,
                                    size: 14,
                                    color: isUser ? JarvisTheme.primaryCyan : JarvisTheme.accentGold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isUser ? 'Siz' : 'JARVIS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isUser ? JarvisTheme.primaryCyan : JarvisTheme.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                msg.content,
                                style: const TextStyle(
                                  color: JarvisTheme.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: JarvisTheme.primaryCyan),
                  ),
                  SizedBox(width: 10),
                  Text('JARVIS ishlamoqda...', style: TextStyle(color: JarvisTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: JarvisTheme.cardBackground,
              border: Border(top: BorderSide(color: JarvisTheme.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'JARVIS uchun buyruq yoki savol yozing...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: JarvisTheme.primaryCyan,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
