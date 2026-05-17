import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pondstat/core/services/settings/settings_provider.dart';
import 'package:pondstat/core/services/settings/settings_keys.dart';

void main() {
  group('SettingsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        SettingsKeys.themeMode: ThemeMode.light.index,
        SettingsKeys.pushNotifications: false,
        SettingsKeys.abnormalAlerts: true,
      });
    });

    Future<void> createContainer() async {
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    }

    test('initializes with values from SharedPreferences', () async {
      await createContainer();
      final state = container.read(settingsProvider);

      expect(state.themeMode, ThemeMode.light);
      expect(state.pushNotifications, false);
      expect(state.abnormalAlerts, true);
    });

    test('updates themeMode and persists to storage', () async {
      await createContainer();
      
      await container.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
      
      final state = container.read(settingsProvider);
      expect(state.themeMode, ThemeMode.dark);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getInt(SettingsKeys.themeMode), ThemeMode.dark.index);
    });

    test('updates pushNotifications and persists to storage', () async {
      await createContainer();
      
      await container.read(settingsProvider.notifier).setPushNotifications(true);
      
      final state = container.read(settingsProvider);
      expect(state.pushNotifications, true);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool(SettingsKeys.pushNotifications), true);
    });
  });
}
