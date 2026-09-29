import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../tools/tool_registry.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final TextEditingController _projectNameController = TextEditingController(text: 'MyJarvisBot');
  String _selectedTemplate = 'python_telegram_bot';
  String _statusOutput = '';
  bool _isGenerating = false;

  void _generateProject() async {
    final name = _projectNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _statusOutput = 'Loyiha yaratilmoqda...';
    });

    final res = await ToolRegistry().execute('create_code_project', {
      'project_name': name,
      'project_type': _selectedTemplate,
      'open_in_vscode': true,
    });

    setState(() {
      _isGenerating = false;
      _statusOutput = res.message;
    });
  }

  void _openDesktop() async {
    await ToolRegistry().execute('file_operations', {
      'operation': 'open_folder',
      'path': 'Desktop',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAYLLAR & DASTURLASH'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.code_rounded, color: JarvisTheme.primaryCyan),
                        SizedBox(width: 10),
                        Text(
                          'Yangi Loyiha Yaratish (VS Code)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JarvisTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Loyiha nomi',
                        hintText: 'Masalan: TelegramBot, WebApp',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTemplate,
                      decoration: const InputDecoration(labelText: 'Loyiha turi'),
                      dropdownColor: JarvisTheme.cardBackground,
                      items: const [
                        DropdownMenuItem(
                          value: 'python_telegram_bot',
                          child: Text('Python Telegram Bot (aiogram 3.x)'),
                        ),
                        DropdownMenuItem(
                          value: 'python_general',
                          child: Text('Python Skript / Loyiha'),
                        ),
                        DropdownMenuItem(
                          value: 'web_html',
                          child: Text('Web HTML / CSS / JS'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTemplate = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.rocket_launch),
                          label: Text(_isGenerating ? 'Yaratilmoqda...' : 'Yaratish va VS Code\'da ochish'),
                          onPressed: _isGenerating ? null : _generateProject,
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Desktop Papkasini Ochish'),
                          onPressed: _openDesktop,
                        ),
                      ],
                    ),
                    if (_statusOutput.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: JarvisTheme.cardBorder),
                        ),
                        child: Text(
                          _statusOutput,
                          style: const TextStyle(color: JarvisTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
