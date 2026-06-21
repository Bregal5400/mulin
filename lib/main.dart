import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MulatschakApp());
}

class MulatschakApp extends StatelessWidget {
  const MulatschakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mulatschak',
      theme: AppTheme.darkGreen,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
