import 'package:flutter/material.dart';

// Defines the consistent dark theme for the entire application.
class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark, // Essential for indicating a dark theme
    primaryColor: Colors.deepPurple, // A prominent color for branding/accents
    colorScheme: ColorScheme.dark(
      primary: Colors.deepPurpleAccent, // Accent color for interactive elements
      secondary: Colors.tealAccent, // Secondary accent color
      surface: Colors.grey[900]!, // Background for cards, dialogs, bottom sheets
      background: Colors.black, // Main background color for Scaffold
      onPrimary: Colors.white, // Text/icon color on primary color
      onSecondary: Colors.black, // Text/icon color on secondary color
      onSurface: Colors.white70, // Text/icon color on surface color
      onBackground: Colors.white, // Text/icon color on background color
      error: Colors.redAccent, // Color for error indications
      onError: Colors.white, // Text/icon color on error color
    ),
    scaffoldBackgroundColor: Colors.black, // The default background color for the Scaffold
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900], // Dark background for AppBars
      foregroundColor: Colors.white, // Color for icons and text in AppBar
      elevation: 4, // Shadow beneath the AppBar
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.white), // Icons in AppBar
    ),
    cardTheme: CardTheme(
      color: Colors.grey[850], // Slightly lighter than background for cards
      elevation: 2, // Shadow beneath cards
      margin: const EdgeInsets.all(8), // Default margin for cards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurpleAccent, // FAB background
      foregroundColor: Colors.white, // FAB icon color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))), // Rounded FAB
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontSize: 57),
      displayMedium: TextStyle(color: Colors.white, fontSize: 45),
      displaySmall: TextStyle(color: Colors.white, fontSize: 36),
      headlineLarge: TextStyle(color: Colors.white, fontSize: 32),
      headlineMedium: TextStyle(color: Colors.white, fontSize: 28),
      headlineSmall: TextStyle(color: Colors.white, fontSize: 24),
      titleLarge: TextStyle(color: Colors.white, fontSize: 22),
      titleMedium: TextStyle(color: Colors.white70, fontSize: 16),
      titleSmall: TextStyle(color: Colors.white70, fontSize: 14),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontSize: 14),
      labelMedium: TextStyle(color: Colors.white70, fontSize: 12),
      labelSmall: TextStyle(color: Colors.white54, fontSize: 11),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800], // Background color for input fields
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none, // No border by default
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!), // Border when enabled
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2), // Border when focused
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2), // Border on error
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2), // Focused error border
      ),
      hintStyle: TextStyle(color: Colors.grey[500]), // Hint text style
      labelStyle: const TextStyle(color: Colors.white70), // Label text style
      prefixIconColor: Colors.grey[400], // Color for prefix icons
      suffixIconColor: Colors.grey[400], // Color for suffix icons
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      buttonColor: Colors.deepPurpleAccent,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent, // Elevated button background
        foregroundColor: Colors.white, // Elevated button text/icon color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.deepPurpleAccent, // Text button text color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white70, // Default icon color
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[700], // Color for dividers
      thickness: 1,
      space: 16,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.grey[850], // Background for dialogs
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16),
    ),
  );
}
