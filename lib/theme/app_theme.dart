import 'package:flutter/material.dart';
import '../models/card.dart';

class AppTheme {
  static ThemeData get darkGreen => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4CAF50),
      secondary: Color(0xFFFFD700),
      surface: Color(0xFF1B5E20),
      error: Color(0xFFEF5350),
    ),
    scaffoldBackgroundColor: const Color(0xFF1B5E20),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
    ),
  );
}

Color suitColor(CardSuit suit) {
  switch (suit) {
    case CardSuit.herz: return const Color(0xFFE53935);
    case CardSuit.schelle: return const Color(0xFFFF8F00);
    case CardSuit.laub: return const Color(0xFF388E3C);
    case CardSuit.eichel: return const Color(0xFF5D4037);
  }
}

String suitSymbolLarge(CardSuit suit) {
  switch (suit) {
    case CardSuit.herz: return '♥';
    case CardSuit.laub: return '♠';
    case CardSuit.schelle: return '◆';
    case CardSuit.eichel: return '♣';
  }
}
