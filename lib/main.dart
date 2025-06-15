import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torneo_unjfsc/screens/matches.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://auypdpzutvyfbgwoeqef.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1eXBkcHp1dHZ5ZmJnd29lcWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MzEyNDAsImV4cCI6MjA2NTUwNzI0MH0.0L3i48HZBWPOZNj4Yb9XompCb7DhlJ6q6PKhELZEKRk',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torneo UNJFSC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Matches(),
    );
  }
}
