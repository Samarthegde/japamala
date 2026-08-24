import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/mantra_provider.dart';
import '../providers/commitment_provider.dart';
import '../providers/session_provider.dart';
import '../services/backup_service.dart';
import '../services/haptic_feedback.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../services/volume_key_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              // Theme Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Theme mode: system / light / dark
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (selection) async {
                    if (themeProvider.hapticEnabled) {
                      await HapticFeedbackService.buttonPress();
                    }
                    await themeProvider.setThemeMode(selection.first);
                  },
                ),
              ),

              const Divider(),

              // Theme Selection
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Color Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Theme Options
              RadioGroup<AppTheme>(
                groupValue: themeProvider.currentTheme,
                onChanged: (value) async {
                  if (value == null) return;
                  if (themeProvider.hapticEnabled) {
                    await HapticFeedbackService.buttonPress();
                  }
                  await themeProvider.setTheme(value);
                },
                child: Column(
                  children: AppTheme.values.map((theme) {
                    return RadioListTile<AppTheme>(
                      title: Text(theme.displayName),
                      value: theme,
                      secondary: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? theme.darkColorScheme.primary
                              : theme.lightColorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(),

              // Practice Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Practice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // How beads are counted on the counter screen.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<CounterGesture>(
                      segments: const [
                        ButtonSegment(
                          value: CounterGesture.swipe,
                          label: Text('Swipe'),
                          icon: Icon(Icons.swipe_down),
                        ),
                        ButtonSegment(
                          value: CounterGesture.tap,
                          label: Text('Tap'),
                          icon: Icon(Icons.touch_app),
                        ),
                      ],
                      selected: {themeProvider.counterGesture},
                      onSelectionChanged: (selection) async {
                        if (themeProvider.hapticEnabled) {
                          await HapticFeedbackService.buttonPress();
                        }
                        await themeProvider.setCounterGesture(selection.first);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      themeProvider.counterGesture.hint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              SwitchListTile(
                title: const Text('Keep Screen On'),
                subtitle: const Text(
                  'Prevent the screen sleeping during practice',
                ),
                value: themeProvider.keepScreenOn,
                onChanged: themeProvider.setKeepScreenOn,
                secondary: const Icon(Icons.screen_lock_portrait),
              ),

              SwitchListTile(
                title: const Text('Daily Reminder'),
                subtitle: Text(
                  themeProvider.reminderEnabled
                      ? 'Every day at ${themeProvider.reminderTime.format(context)}'
                      : 'A daily nudge to sit for practice',
                ),
                value: themeProvider.reminderEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Don't promise a reminder the OS won't deliver.
                    final granted =
                        await NotificationService.requestPermission();
                    if (!granted) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notifications are turned off for Japamala. '
                              'Enable them in system settings to get reminders.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    await NotificationService.scheduleDailyReminder(
                      themeProvider.reminderTime,
                    );
                  } else {
                    await NotificationService.cancelDailyReminder();
                  }
                  await themeProvider.setReminderEnabled(value);
                },
                secondary: const Icon(Icons.alarm),
              ),

              if (themeProvider.reminderEnabled)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Reminder Time'),
                  subtitle: Text(themeProvider.reminderTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: themeProvider.reminderTime,
                    );
                    if (picked == null) return;
                    await themeProvider.setReminderTime(picked);
                    await NotificationService.scheduleDailyReminder(picked);
                  },
                ),

              if (VolumeKeyService.isSupported)
                SwitchListTile(
                  title: const Text('Volume Key Counting'),
                  subtitle: const Text(
                    'Count beads with the volume keys while on the counter',
                  ),
                  value: themeProvider.volumeKeyCounting,
                  onChanged: themeProvider.setVolumeKeyCounting,
                  secondary: const Icon(Icons.volume_up),
                ),

              const Divider(),

              // Haptic Feedback Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SwitchListTile(
                title: const Text('Completion Bell'),
                subtitle: const Text('Play a bell when a round or timer ends'),
                value: themeProvider.soundEnabled,
                onChanged: (value) async {
                  await themeProvider.setSoundEnabled(value);
                  if (value) await SoundService.bell();
                },
                secondary: const Icon(Icons.notifications_active),
              ),

              // Haptic Feedback Toggle
              SwitchListTile(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibration feedback for interactions'),
                value: themeProvider.hapticEnabled,
                onChanged: (value) async {
                  await themeProvider.setHapticEnabled(value);
                  if (value) {
                    await HapticFeedbackService.buttonPress();
                  }
                },
                secondary: const Icon(Icons.vibration),
              ),

              // Test Haptic Feedback
              if (themeProvider.hapticEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await HapticFeedbackService.beadCount();
                      await Future.delayed(const Duration(milliseconds: 200));
                      await HapticFeedbackService.mantraComplete();
                      await Future.delayed(const Duration(milliseconds: 300));
                      await HapticFeedbackService.sessionComplete();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Haptic Patterns'),
                  ),
                ),

              const Divider(),

              // Backup Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Export Data'),
                subtitle: const Text(
                  'Save mantras, sessions, history and journal',
                ),
                onTap: () => _exportData(context),
              ),

              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from Backup'),
                subtitle: const Text('Merge a backup file into your data'),
                onTap: () => _restoreData(context),
              ),

              const Divider(),

              // About Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'About',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const ListTile(
                title: Text('Japamala App'),
                subtitle: Text(
                  'Digital mantra counting for spiritual practice',
                ),
              ),

              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return ListTile(
                    title: const Text('Version'),
                    subtitle: Text(
                      info == null
                          ? '...'
                          : '${info.version} (${info.buildNumber})',
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await BackupService.exportToFile();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Japamala backup'),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export: $e')));
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final mantraProvider = context.read<MantraProvider>();
    final sessionProvider = context.read<SessionProvider>();
    final commitmentProvider = context.read<CommitmentProvider>();

    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Choose a Japamala backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = picked?.path;
      if (path == null) return; // Cancelled

      final summary = await BackupService.restore(
        await File(path).readAsString(),
      );

      // The restore wrote straight into the Hive boxes, so the providers are
      // holding stale lists until they re-read.
      await mantraProvider.reload();
      await sessionProvider.reload();
      await commitmentProvider.reload();

      messenger.showSnackBar(SnackBar(content: Text('Restored $summary')));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not restore: $e')));
    }
  }
}
