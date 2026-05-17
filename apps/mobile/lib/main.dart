import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:core/core.dart' as core;
import 'package:drift/native.dart';

import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';

late RecallDatabase database;
late CardRepository cardRepository;
late CardGenerationService cardGenerationService;
late SavedFilterEngine savedFilterEngine;
late ProgressTracker progressTracker;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = RecallDatabase(NativeDatabase.memory());
  cardRepository = CardRepository(database);
  cardGenerationService = core.StubCardGenerationService();
  savedFilterEngine = core.SavedFilterEngine(database);
  progressTracker = core.ProgressTracker(database);
  runApp(const RecallApp());
}

class RecallApp extends StatelessWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          LibraryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.library_books), label: 'Library'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
