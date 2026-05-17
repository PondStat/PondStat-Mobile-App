import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_metrics.dart';
import 'pond_status_colors.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.customBlue,
    primary: AppColors.customBlue,
    secondary: AppColors.secondaryBlue,
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: AppColors.slate800,
    outline: AppColors.slate400,
    surfaceContainerHighest: AppColors.slate100,
    error: Colors.redAccent,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.customBlue,
    primary: AppColors.secondaryBlue,
    secondary: AppColors.customBlue,
    brightness: Brightness.dark,
    surface: AppColors.slate900,
    onSurface: AppColors.slate50,
    outline: AppColors.slate600,
    surfaceContainerHighest: AppColors.slate800,
    error: Colors.redAccent.shade200,
  );

  static final _lightPondColors = const PondStatusColors(
    healthy: Color(0xFF0D9488),
    warning: Color(0xFFB45309), // Amber 700 - Better contrast for white text
    critical: Color(0xFFE11D48),
  );

  static final _darkPondColors = const PondStatusColors(
    healthy: Color(0xFF2DD4BF),
    warning: Color(0xFFFBBF24), // Amber 400 - OK on dark slate
    critical: Color(0xFFFB7185),
  );

  static ThemeData get lightTheme {
    return _buildTheme(colorScheme: _lightColorScheme, isDark: false);
  }

  static ThemeData get darkTheme {
    return _buildTheme(colorScheme: _darkColorScheme, isDark: true);
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? _darkPondColors : _lightPondColors,
        AppMetrics.standard(),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Maps to radiusLarge
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        iconColor: isDark ? Colors.white70 : AppColors.slate600,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.slate800 : AppColors.slate100,
        disabledColor: isDark
            ? AppColors.slate800.withValues(alpha: 0.5)
            : AppColors.slate100.withValues(alpha: 0.5),
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.slate50 : AppColors.slate800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Maps to radiusMedium
          side: BorderSide(
            color: isDark ? AppColors.slate600 : AppColors.slate400,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48), // A11y Tap Target
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Maps to radiusButton
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48), // A11y Tap Target
          elevation: 0,
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 2),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48), // A11y Tap Target
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
    );
  }
}
