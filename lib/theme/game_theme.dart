import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class GamePalette {
  static const paper = Color(0xFFF6F1E7);
  static const ink = Color(0xFF252720);
  static const orange = Color(0xFFEF5B35);
  static const muted = Color(0xFF6A6D60);
  static const accentInk = Color(0xFFB63A1C);
  static const line = Color(0xFFDDD8CC);
  static const surface = Color(0xFFFFFDF7);
  static const sage = Color(0xFFBEC8A8);
}

abstract final class GameTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GamePalette.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GamePalette.orange,
        primary: GamePalette.ink,
        onPrimary: GamePalette.paper,
        secondary: GamePalette.orange,
        surface: GamePalette.paper,
        onSurface: GamePalette.ink,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.tajawalTextTheme(
        base.textTheme,
      ).apply(bodyColor: GamePalette.ink, displayColor: GamePalette.ink),
      dividerTheme: const DividerThemeData(
        color: GamePalette.line,
        thickness: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: GamePalette.orange,
        selectionColor: Color(0x44EF5B35),
        selectionHandleColor: GamePalette.orange,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GamePalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        hintStyle: const TextStyle(color: GamePalette.muted, fontSize: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GamePalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GamePalette.ink, width: 1.5),
        ),
      ),
    );
  }
}
