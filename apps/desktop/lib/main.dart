import 'package:flutter/material.dart';

void main() {
  runApp(const RecallDesktopApp());
}

class RecallDesktopApp extends StatelessWidget {
  const RecallDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Recall Desktop')),
      ),
    );
  }
}
