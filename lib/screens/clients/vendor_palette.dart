import 'package:flutter/material.dart';

class VendorPalette {
  static const Color featureBrown = Color(0xFF5A3F37);
  static const Color featureGreen = Color(0xFF2C7744);
  static const Color lightPage = Color(0xFFF6F4F1);
  static const Color darkPage = Color(0xFF121212);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color page(BuildContext context) =>
      isDark(context) ? darkPage : lightPage;

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1C) : Colors.white;

  static Color elevatedSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF242424) : const Color(0xFFFFFCF8);

  static Color mutedSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFF1ECE6);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF343434) : const Color(0xFFE1D8CF);

  static Color text(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1F2937);

  static Color mutedText(BuildContext context) =>
      isDark(context) ? const Color(0xFFBDBDBD) : const Color(0xFF6B7280);

  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFF7CCB8D) : featureGreen;

  static Color warmAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFFC8A99B) : featureBrown;

  static Color accentSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFF203827) : const Color(0xFFEAF4EC);

  static Color danger(BuildContext context) =>
      isDark(context) ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);

  static Color success(BuildContext context) =>
      isDark(context) ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);

  static LinearGradient headerGradient(BuildContext context) => LinearGradient(
    colors: isDark(context)
        ? const [Color(0xFF2A211E), Color(0xFF183323)]
        : const [Color(0xFFF4EDE8), Color(0xFFE6F2E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> featureGradient(BuildContext context) => isDark(context)
      ? const [Color(0xFFC8A99B), Color(0xFF7CCB8D)]
      : const [featureBrown, featureGreen];

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final borderRadius = BorderRadius.circular(14);
    final outline = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: border(context)),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: elevatedSurface(context),
      labelStyle: TextStyle(color: mutedText(context)),
      hintStyle: TextStyle(color: mutedText(context)),
      prefixIconColor: mutedText(context),
      enabledBorder: outline,
      border: outline,
      focusedBorder: outline.copyWith(
        borderSide: BorderSide(color: accent(context), width: 1.6),
      ),
    );
  }

  static ButtonStyle primaryButton(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: accent(context),
        foregroundColor: Colors.white,
        disabledBackgroundColor: mutedSurface(context),
        disabledForegroundColor: mutedText(context),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static ButtonStyle dangerButton(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: danger(context),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static ButtonStyle textButton(BuildContext context) => TextButton.styleFrom(
    foregroundColor: accent(context),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
