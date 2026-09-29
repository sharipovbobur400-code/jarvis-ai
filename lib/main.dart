import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/config/theme.dart';
import 'core/storage/local_database.dart';
import 'voice/text_to_speech.dart';
import 'voice/speech_to_text.dart';
import 'screens/home/home_screen.dart';
import 'screens/brain/brain_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/files/files_screen.dart';
import 'screens/remote/remote_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core singletons
  final config = AppConfig();
  await config.init();

  final db = LocalDatabaseService();
  await db.init();

  final tts = TTSService();
  await tts.init();

  final stt = STTService();
  await stt.init();

  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS AI',
      debugShowCheckedModeBanner: false,
      theme: JarvisTheme.darkTheme,
      home: const JarvisMainNavigationShell(),
    );
  }
}

class JarvisMainNavigationShell extends StatefulWidget {
  const JarvisMainNavigationShell({super.key});

  @override
  State<JarvisMainNavigationShell> createState() => _JarvisMainNavigationShellState();
}

class _JarvisMainNavigationShellState extends State<JarvisMainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BrainScreen(),
    TasksScreen(),
    FilesScreen(),
    RemoteScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (isDesktop && MediaQuery.of(context).size.width > 700) {
      // Desktop Sidebar Layout
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (val) => setState(() => _currentIndex = val),
              backgroundColor: JarvisTheme.cardBackground,
              selectedIconTheme: const IconThemeData(color: JarvisTheme.primaryCyan),
              unselectedIconTheme: const IconThemeData(color: JarvisTheme.textMuted),
              selectedLabelTextStyle: const TextStyle(color: JarvisTheme.primaryCyan, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: JarvisTheme.textMuted),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: JarvisTheme.primaryCyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: JarvisTheme.primaryCyan.withValues(alpha: 0.3), blurRadius: 10),
                        ],
                      ),
                      child: const Icon(Icons.blur_on, color: JarvisTheme.primaryCyan, size: 28),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'JARVIS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: JarvisTheme.primaryCyan,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Bosh sahifa'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.psychology_outlined),
                  selectedIcon: Icon(Icons.psychology),
                  label: Text('AI Miya'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Vazifalar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('Fayllar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.phonelink_ring_outlined),
                  selectedIcon: Icon(Icons.phonelink_ring),
                  label: Text('Remote'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Sozlamalar'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: JarvisTheme.cardBorder),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile / Tablet Bottom Navigation
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (val) => setState(() => _currentIndex = val),
        backgroundColor: JarvisTheme.cardBackground,
        indicatorColor: JarvisTheme.primaryCyan.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: JarvisTheme.primaryCyan),
            label: 'Bosh sahifa',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: JarvisTheme.primaryCyan),
            label: 'AI Miya',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: JarvisTheme.primaryCyan),
            label: 'Vazifalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: JarvisTheme.primaryCyan),
            label: 'Fayllar',
          ),
          NavigationDestination(
            icon: Icon(Icons.phonelink_ring_outlined),
            selectedIcon: Icon(Icons.phonelink_ring, color: JarvisTheme.primaryCyan),
            label: 'Remote',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: JarvisTheme.primaryCyan),
            label: 'Sozlamalar',
          ),
        ],
      ),
    );
  }
}
