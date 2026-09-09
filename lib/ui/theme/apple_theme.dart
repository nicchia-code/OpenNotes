import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Apple Notes Design System (macOS Sequoia & iOS 18 fidelity).
class AppleTheme {
  // Apple Notes Golden Yellow Accent
  static const Color accentYellow = Color(0xFFEBA625);
  static const Color accentYellowDark = Color(0xFFC7870E);
  static const Color accentYellowLight = Color(0xFFFFF4D4);
  /// High-contrast amber for text/icons on light backgrounds (WCAG AA: > 5.1:1 on white).
  static const Color accentAmberLight = Color(0xFF965F00);

  /// Returns high-contrast accent color appropriate for text/icons depending on brightness.
  static Color adaptiveAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? accentYellow : accentAmberLight;
  }

  // macOS Window & Traffic Lights
  static const Color trafficRed = Color(0xFFFF5F56);
  static const Color trafficYellow = Color(0xFFFFBD2E);
  static const Color trafficGreen = Color(0xFF27C93F);

  // Light Mode Colors (macOS Sequoia)
  static const Color lightSidebar = Color(0xFFE8E8ED);
  static const Color lightNoteList = Color(0xFFF6F6F7);
  static const Color lightEditor = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardSelected = Color(0xFFFFE69E);
  static const Color lightCardHover = Color(0xFFECECF0);
  static const Color lightDivider = Color(0xFFDCDCE0);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF86868B);
  static const Color lightSearchBg = Color(0xFFE1E1E6);

  // Dark Mode Colors (macOS Sequoia Dark)
  static const Color darkSidebar = Color(0xFF1E1E20);
  static const Color darkNoteList = Color(0xFF262629);
  static const Color darkEditor = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkCardSelected = Color(0xFF453612);
  static const Color darkCardHover = Color(0xFF323236);
  static const Color darkDivider = Color(0xFF38383C);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF98989D);
  static const Color darkSearchBg = Color(0xFF2E2E33);

  // Checkbox Colors
  static const Color checkboxBorder = Color(0xFFA1A1A6);
  static const Color checkboxChecked = accentYellow;

  /// Builds the light theme with crisp Cupertino typography
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentYellow,
      scaffoldBackgroundColor: lightEditor,
      dividerColor: lightDivider,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: accentYellow,
        secondary: accentYellowDark,
        surface: lightEditor,
        onSurface: lightTextPrimary,
        outline: lightDivider,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightEditor,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: accentYellow,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightEditor,
      ),
    );
  }

  /// Builds the dark theme with crisp Cupertino typography
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentYellow,
      scaffoldBackgroundColor: darkEditor,
      dividerColor: darkDivider,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: accentYellowDark,
        surface: darkEditor,
        onSurface: darkTextPrimary,
        outline: darkDivider,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkEditor,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: accentYellow,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkEditor,
      ),
    );
  }
}
