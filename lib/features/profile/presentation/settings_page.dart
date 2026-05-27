import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/services/settings/settings_provider.dart';
import 'package:pondstat/features/profile/presentation/widgets/settings_switch_tile.dart';
import 'package:pondstat/features/profile/presentation/widgets/settings_list_tile.dart';

import 'package:pondstat/core/services/notification_service.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          final settings = ref.watch(settingsProvider);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader('APPEARANCE'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        HapticFeedback.selectionClick();
                        ref.read(settingsProvider.notifier).setThemeMode(newSelection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return theme.colorScheme.primary.withValues(alpha: 0.2);
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('NOTIFICATIONS'),
              SettingsSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive general app notifications',
                value: settings.pushNotifications,
                onChanged: (val) async {
                  HapticFeedback.lightImpact();
                  if (val) {
                    final granted = await ref
                        .read(notificationServiceProvider)
                        .requestPermission();
                    if (context.mounted) {
                      ref
                          .read(settingsProvider.notifier)
                          .setPushNotifications(granted);
                      if (!granted) {
                        SnackbarHelper.showError(
                          context,
                          'Permission denied. Please enable notifications in settings.',
                        );
                      }
                    }
                  } else {
                    ref
                        .read(settingsProvider.notifier)
                        .setPushNotifications(false);
                  }
                },
              ),
              SettingsSwitchTile(
                icon: Icons.warning_amber_rounded,
                title: 'Abnormal Alerts',
                subtitle: 'Get notified for critical parameter changes',
                value: settings.abnormalAlerts,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  ref.read(settingsProvider.notifier).setAbnormalAlerts(val);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('HELP & TUTORIAL'),
              SettingsListTile(
                icon: Icons.restart_alt_rounded,
                title: 'Reset Onboarding Tour',
                subtitle: 'Replay the step-by-step navigation guides',
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(onboardingTourProvider.notifier).resetAll();
                  if (context.mounted) {
                    SnackbarHelper.showInfo(
                      context,
                      'Onboarding tour reset. Start a tour from the dashboard or monitoring screen!',
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('ABOUT & SUPPORT'),
              SettingsListTile(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              SettingsListTile(
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              SettingsListTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: '1.0.0 (Build 1)',
                onTap: null, // Fixing the dead tap
                showChevron: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
