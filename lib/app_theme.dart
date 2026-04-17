import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PondStatusColors extends ThemeExtension<PondStatusColors> {
  final Color? healthy;
  final Color? warning;
  final Color? critical;

  const PondStatusColors({this.healthy, this.warning, this.critical});

  @override
  ThemeExtension<PondStatusColors> copyWith({
    Color? healthy,
    Color? warning,
    Color? critical,
  }) {
    return PondStatusColors(
      healthy: healthy ?? this.healthy,
      warning: warning ?? this.warning,
      critical: critical ?? this.critical,
    );
  }

  @override
  ThemeExtension<PondStatusColors> lerp(
    ThemeExtension<PondStatusColors>? other,
    double t,
  ) {
    if (other is! PondStatusColors) {
      return this;
    }
    return PondStatusColors(
      healthy: Color.lerp(healthy, other.healthy, t),
      warning: Color.lerp(warning, other.warning, t),
      critical: Color.lerp(critical, other.critical, t),
    );
  }
}

class AppTheme {
  static const Color customBlue = Color(0xFF0A74DA); // Updated to main primary blue
  static const Color secondaryBlue = Color(0xFF4FA0F0);
  
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: customBlue,
    primary: customBlue,
    secondary: secondaryBlue,
    brightness: Brightness.light,
    surface: Colors.white, // Cleaner surface
    onSurface: const Color(0xFF1E293B), // Slate 800
    error: Colors.redAccent,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: customBlue,
    primary: secondaryBlue,
    secondary: customBlue,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F172A),
    onSurface: const Color(0xFFF8FAFC),
    error: Colors.redAccent.shade200,
  );

  static final _lightPondColors = PondStatusColors(
    healthy: Colors.green.shade600,
    warning: Colors.orange.shade600,
    critical: Colors.red.shade600,
  );

  static final _darkPondColors = PondStatusColors(
    healthy: Colors.green.shade400,
    warning: Colors.orange.shade400,
    critical: Colors.red.shade400,
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
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC), // Slate 50
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? _darkPondColors : _lightPondColors,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 100
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: colorScheme.error.withValues(alpha: 0.5), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8), // Slate 400
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF64748B), // Slate 500
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
        prefixIconColor: isDark ? Colors.white54 : const Color(0xFF94A3B8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0, // Flat buttons, use shadow in container if needed
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFF1E293B), // Dark even on light mode for contrast
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        elevation: 0,
      ),
    );
  }
}
