import 'package:flutter/material.dart';

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
  static const Color customBlue = Color(0xFF0077C2);

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: customBlue,
    primary: customBlue,
    brightness: Brightness.light,
    surface: Colors.grey.shade50,
    onSurface: Colors.black87,
    error: Colors.redAccent,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: customBlue,
    primary: Colors.lightBlue.shade300,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F172A),
    onSurface: const Color(0xE7FFFFFF),
    error: Colors.redAccent.shade200,
  );

  // Cached Theme Extensions to prevent unnecessary recreation
  static final _lightPondColors = PondStatusColors(
    healthy: Colors.green.shade600,
    warning: Colors.orange.shade600,
    critical: Colors.red.shade600,
  );

  static final _darkPondColors = PondStatusColors(
    healthy: Colors.green.shade400,
    warning: Colors.orange.shade300,
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
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? _darkPondColors : _lightPondColors,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        foregroundColor: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
        prefixIconColor: isDark ? Colors.white54 : Colors.grey.shade600,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        indicatorColor: colorScheme.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : Colors.grey.shade900,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.grey.shade50,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      textTheme: isDark
          ? ThemeData.dark().textTheme.apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            )
          : ThemeData.light().textTheme.apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            ),
    );
  }
}
