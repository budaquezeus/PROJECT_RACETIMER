import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RaceTimerApp());
}

class RaceTimerApp extends StatelessWidget {
  const RaceTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Race Timer Drag Race',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}