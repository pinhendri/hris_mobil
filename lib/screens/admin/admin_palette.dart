import 'package:flutter/material.dart';

class AdminPalette {
  static const Color accent = Color(0xFFFF9628);
  static const Color lightPage = Color(0xFFF6F4F1);
  static const Color darkPage = Color(0xFF020817);
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF111827);
  static const Color lightMutedSurface = Color(0xFFF8F6F2);
  static const Color darkMutedSurface = Color(0xFF0F172A);
  static const Color lightBorder = Color(0xFFEAE7E2);
  static const Color darkBorder = Color(0xFF253041);
  static const Color lightText = Color(0xFF1F2937);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color lightMutedText = Color(0xFF6B7280);
  static const Color darkMutedText = Color(0xFFCBD5E1);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color page(BuildContext context) {
    return isDark(context) ? darkPage : lightPage;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color mutedSurface(BuildContext context) {
    return isDark(context) ? darkMutedSurface : lightMutedSurface;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color text(BuildContext context) {
    return isDark(context) ? darkText : lightText;
  }

  static Color mutedText(BuildContext context) {
    return isDark(context) ? darkMutedText : lightMutedText;
  }

  static List<BoxShadow> shadow(BuildContext context) {
    if (isDark(context)) {
      return const [];
    }

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
