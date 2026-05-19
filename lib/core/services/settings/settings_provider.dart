import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';

import 'settings_keys.dart';
import 'settings_state.dart';

/// Provider for the [SharedPreferences] instance.
/// Must be overridden in main.dart via ProviderScope.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadSettings();
  }

  /// Synchronously loads settings from [SharedPreferences].
  SettingsState _loadSettings() {
    final themeModeIndex = _prefs.getInt(SettingsKeys.themeMode);
    final pushNotifications = _prefs.getBool(SettingsKeys.pushNotifications) ?? true;
    final abnormalAlerts = _prefs.getBool(SettingsKeys.abnormalAlerts) ?? true;

    // Map index back to ThemeMode, defaulting to ThemeMode.system
    ThemeMode themeMode = ThemeMode.system;
    if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length) {
      themeMode = ThemeMode.values[themeModeIndex];
    } else {
      // Legacy fallback: convert old 'darkMode' bool to ThemeMode
      final isDarkMode = _prefs.getBool('darkMode');
      if (isDarkMode != null) {
        themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
    }

    return SettingsState(
      themeMode: themeMode,
      pushNotifications: pushNotifications,
      abnormalAlerts: abnormalAlerts,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final previousState = state;
    state = state.copyWith(themeMode: mode);

    try {
      final success = await _prefs.setInt(SettingsKeys.themeMode, mode.index);
      if (!success) throw Exception('Failed to write themeMode to storage.');
    } catch (e, stack) {
      ref.read(appLoggerProvider).error('Settings Storage Error', error: e, stackTrace: stack, tag: 'SETTINGS');
      // Rollback on failure
      state = previousState;
    }
  }

  Future<void> setPushNotifications(bool value) async {
    final previousState = state;
    state = state.copyWith(pushNotifications: value);

    try {
      final success = await _prefs.setBool(SettingsKeys.pushNotifications, value);
      if (!success) throw Exception('Failed to write pushNotifications to storage.');
    } catch (e, stack) {
      ref.read(appLoggerProvider).error('Settings Storage Error', error: e, stackTrace: stack, tag: 'SETTINGS');
      state = previousState;
    }
  }

  Future<void> setAbnormalAlerts(bool value) async {
    final previousState = state;
    state = state.copyWith(abnormalAlerts: value);

    try {
      final success = await _prefs.setBool(SettingsKeys.abnormalAlerts, value);
      if (!success) throw Exception('Failed to write abnormalAlerts to storage.');
    } catch (e, stack) {
      ref.read(appLoggerProvider).error('Settings Storage Error', error: e, stackTrace: stack, tag: 'SETTINGS');
      state = previousState;
    }
  }
}
