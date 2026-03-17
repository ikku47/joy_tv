import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1); // Soft Violet for premium accent
  static const Color accentColor = Color(0xFFFACC15); // Golden Yellow for accent highlights
  static const Color backgroundColor = Color(0xFF000000); // True black for AMOLED effect
  static const Color surfaceColor = Color(0xFF000000); // True black for surface as well

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withOpacity(0.8), // Darker card to match black background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners for a premium touch
        elevation: 2, // Slight elevation for material feel
      ),
      appBarTheme: AppBarTheme(
        color: surfaceColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0, // Flat AppBar for a smooth, seamless experience
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor, // Consistent accent color for buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        elevation: 5,
      ),
    );
  }

  // Glassmorphism effect for background overlays with a matte feel
  static BoxDecoration glassDecoration({double opacity = 0.1, double radius = 16}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity), // White with reduced opacity for matte glass feel
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2), // Slight border to enhance separation
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25), // Stronger shadow for a premium effect
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}