import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const appBackground = Color(0xFF090D14);
  static const appSurface = Color(0xFF0F1624);
  static const appBorder = Color(0xFF1E2A40);
  static const appText = Color(0xFFE8EEF8);
  static const appMuted = Color(0xFF8FA0BC);
  static const appDim = Color(0xFF6F829E);
  static const appPrimary = Color(0xFF4D8BFF);
  static const appOnPrimary = Color(0xFF04112B);
  static const appConsole = Color(0xFF060A11);
  static const appError = Color(0xFFFF6B6B);
  static const appSuccess = Color(0xFF5BD68A);
  static const appWarning = Color(0xFFFFB86B);
  static const appCyan = Color(0xFF6FD3E8);
  static const appOutline = Color(0xFF34435E);
  static const appBorderHigh = Color(0xFF2A3A58);

  static const cardRadius = 14.0;
  static const controlRadius = 10.0;

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: appBackground,
        fontFamily: 'Tajawal',
        colorScheme: const ColorScheme.dark(
          primary: appPrimary,
          onPrimary: appOnPrimary,
          surface: appSurface,
          onSurface: appText,
          error: appError,
          surfaceContainerHigh: appSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: appBackground,
          foregroundColor: appText,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: appText,
            fontFamily: 'Tajawal',
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        dividerTheme: const DividerThemeData(color: appBorder, thickness: 1),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: appSurface,
          contentTextStyle: TextStyle(color: appText, fontFamily: 'Tajawal'),
          behavior: SnackBarBehavior.floating,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: appPrimary,
            foregroundColor: appOnPrimary,
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: appText,
            side: const BorderSide(color: appOutline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      );
}
