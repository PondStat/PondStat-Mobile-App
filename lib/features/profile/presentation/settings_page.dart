import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/services/settings/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final Color primaryBlue = const Color(0xFF0A74DA);

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
                              return primaryBlue.withValues(alpha: 0.2);
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
              _buildSwitchTile(
                context: context,
                icon: Icons.notifications_active_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive general app notifications',
                value: settings.pushNotifications,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  ref.read(settingsProvider.notifier).setPushNotifications(val);
                },
              ),
              _buildSwitchTile(
                context: context,
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
              _buildSectionHeader('ABOUT & SUPPORT'),
              _buildListTile(
                context: context,
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              _buildListTile(
                context: context,
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
  }  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: primaryBlue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textMuted, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: textDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: textMuted,
                ),
              )
            : null,
        value: value,
        onChanged: onChanged,
        activeThumbColor: primaryBlue,
        activeTrackColor: primaryBlue.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textMuted, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: textDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: textMuted,
                ),
              )
            : null,
        trailing: showChevron
            ? Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
