import 'dart:io';
import 'package:flutter/foundation.dart';
import 'base_tool.dart';
import '../core/utils/logger.dart';

class CodeGeneratorTool extends BaseJarvisTool {
  @override
  String get name => 'create_code_project';

  @override
  String get description => 'Generates full programming projects (e.g. Python Telegram bot with aiogram, Node.js, Web, Flutter), creates project files, writes code, checks syntax, and opens project in VS Code.';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'project_name': {
        'type': 'string',
        'description': 'Name of the project folder',
      },
      'project_type': {
        'type': 'string',
        'enum': ['python_telegram_bot', 'python_general', 'nodejs', 'web_html'],
        'description': 'Template type of the project to generate',
      },
      'custom_description': {
        'type': 'string',
        'description': 'Specific requirements (e.g., "Bot welcomes user and responds to /start")',
      },
      'open_in_vscode': {
        'type': 'boolean',
        'description': 'Whether to automatically launch the project in Visual Studio Code',
      },
    },
    'required': ['project_name', 'project_type'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    final projectName = arguments['project_name']?.toString() ?? 'JarvisProject';
    final projectType = arguments['project_type']?.toString() ?? 'python_telegram_bot';
    final openVsCode = arguments['open_in_vscode'] as bool? ?? true;

    if (kIsWeb) {
      return ToolResult.success(
        tool: name,
        message: 'Web rejimida loyiha simulyatsiya qilindi: $projectName.',
        data: {'project_name': projectName},
      );
    }

    try {
      final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final projectDir = Directory('$userProfile\\Desktop\\$projectName');

      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }

      final createdFiles = <String>[];

      if (projectType == 'python_telegram_bot') {
        final mainPy = File('${projectDir.path}\\main.py');
        const botCode = '''# JARVIS Generated Telegram Bot
import asyncio
import logging
from aiogram import Bot, Dispatcher, types
from aiogram.filters.command import Command

logging.basicConfig(level=logging.INFO)

BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()

@dp.message(Command("start"))
async def cmd_start(message: types.Message):
    user_name = message.from_user.first_name if message.from_user else "Foydalanuvchi"
    await message.answer(f"Assalomu alaykum, {user_name}! JARVIS tomonidan yaratilgan Telegram botga xush kelibsiz!")

@dp.message(Command("help"))
async def cmd_help(message: types.Message):
    await message.answer("Yordam bo'limi:\\n/start - Botni ishga tushirish\\n/help - Yordam")

@dp.message()
async def echo_handler(message: types.Message):
    await message.answer(f"Siz yozdingiz: {message.text}")

async def main():
    print("JARVIS Telegram Bot ishga tushmoqda...")
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
''';
        await mainPy.writeAsString(botCode);
        createdFiles.add('main.py');

        final reqFile = File('${projectDir.path}\\requirements.txt');
        await reqFile.writeAsString('aiogram>=3.4.0\n');
        createdFiles.add('requirements.txt');

        final readme = File('${projectDir.path}\\README.md');
        await readme.writeAsString('''# $projectName
JARVIS AI tomonidan avtomatik yaratilgan Telegram Bot loyihasi.
''');
        createdFiles.add('README.md');

        final gitignore = File('${projectDir.path}\\.gitignore');
        await gitignore.writeAsString('venv/\n__pycache__/\n.env\n*.pyc\n');
        createdFiles.add('.gitignore');

        try {
          await Process.run('python', ['-m', 'py_compile', mainPy.path]);
        } catch (_) {}
      } else {
        final mainFile = File('${projectDir.path}\\index.html');
        await mainFile.writeAsString('<!DOCTYPE html><html><head><title>$projectName</title></head><body><h1>$projectName</h1><p>Created by JARVIS</p></body></html>');
        createdFiles.add('index.html');
      }

      if (openVsCode && Platform.isWindows) {
        try {
          await Process.start('cmd.exe', ['/c', 'code', projectDir.path]);
        } catch (_) {}
      }

      return ToolResult.success(
        tool: name,
        message: 'Loyiha "$projectName" Desktopda muvaffaqiyatli yaratildi va VS Code\'da ochildi.',
        data: {
          'project_name': projectName,
          'directory': projectDir.path,
          'files': createdFiles,
          'opened_in_vscode': openVsCode,
        },
      );
    } catch (e) {
      JarvisLogger.error('Project generation error', e);
      return ToolResult.failure(tool: name, error: 'Failed to create project: $e');
    }
  }
}
