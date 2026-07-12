import 'package:flutter/material.dart';

/// الثيم العام لتطبيق eGaming (الفصل 9.13 / 9.16)
/// يدعم الوضع الفاتح والداكن، مع اعتماد هوية بصرية مستوحاة من eFootball.
class AppTheme {
  static const Color primarySeed = Color(0xFF1565C0);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primarySeed,
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: primarySeed,
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  /// يحوّل كود لون Hex (#RRGGBB) إلى Color، مع لون افتراضي عند الفشل
  static Color colorFromHex(String? hex, {Color fallback = primarySeed}) {
    if (hex == null || hex.isEmpty) return fallback;
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }
}
