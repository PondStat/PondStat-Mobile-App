import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PondStatusColors extends ThemeExtension<PondStatusColors> {
  final Color healthy;
  final Color warning;
  final Color critical;

  const PondStatusColors({
    required this.healthy,
    required this.warning,
    required this.critical,
  });

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
      healthy: Color.lerp(healthy, other.healthy, t) ?? healthy,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      critical: Color.lerp(critical, other.critical, t) ?? critical,
    );
  }
}

extension ThemeContextExtension on BuildContext {
  PondStatusColors get pondColors =>
      Theme.of(this).extension<PondStatusColors>()!;
}

class AppTheme {
  AppTheme._();

  static const Color customBlue = Color(
    0xFF0A74DA,
  );
  static const Color secondaryBlue = Color(0xFF4FA0F0);

  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate950 = Color(0xFF0B1120);

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: customBlue,
    primary: customBlue,
    secondary: secondaryBlue,
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: _slate800,
    error: Colors.redAccent,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: customBlue,
    primary: secondaryBlue,
    secondary: customBlue,
    brightness: Brightness.dark,
    surface: _slate900,
    onSurface: _slate50,
    error: Colors.redAccent.shade200,
  );

  static final _lightPondColors = const PondStatusColors(
    healthy: Color(0xFF0D9488),
    warning: Color(0xFFD97706),
    critical: Color(0xFFE11D48),
  );

  static final _darkPondColors = const PondStatusColors(
    healthy: Color(0xFF2DD4BF),
    warning: Color(0xFFFBBF24),
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
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _slate950 : _slate50,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? _darkPondColors : _lightPondColors,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface.withValues(
          alpha: 0.95,
        ),
        scrolledUnderElevation: 4,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _slate800 : Colors.white,
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
        fillColor: isDark ? _slate800 : _slate100,
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
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : _slate500,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : _slate500,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
        prefixIconColor: isDark
            ? Colors.white70
            : _slate500,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 18.0,
                horizontal: 24.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return isDark ? _slate800 : _slate100;
                }
                return colorScheme.primary;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return isDark ? Colors.white38 : _slate400;
                }
                return Colors.white;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _slate800,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
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
