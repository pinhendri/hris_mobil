import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    ),
    cardTheme: const CardThemeData(  // GANTI: CardTheme → CardThemeData
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.orange,
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
      error: Colors.red,
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
      bodyLarge: GoogleFonts.poppins(color: Colors.black87),
      bodyMedium: GoogleFonts.poppins(color: Colors.black54),
      labelLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500),
    ),
    dividerColor: Colors.grey.shade300,
    iconTheme: const IconThemeData(color: Colors.black54),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue.shade700,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(  // GANTI: CardTheme → CardThemeData
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue.shade700,
      secondary: Colors.orange.shade700,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      error: Colors.red.shade700,
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.poppins(color: Colors.white70),
      bodyMedium: GoogleFonts.poppins(color: Colors.white60),
      labelLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white70),
    ),
    dividerColor: Colors.grey.shade800,
    iconTheme: const IconThemeData(color: Colors.white70),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.blue.shade300,
      unselectedItemColor: Colors.grey.shade600,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
    ),
  );
}