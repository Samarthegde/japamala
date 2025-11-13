import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              // Theme Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Dark Mode Toggle
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between light and dark themes'),
                value: themeProvider.isDarkMode,
                onChanged: (value) async {
                  if (themeProvider.hapticEnabled) {
                    await HapticFeedbackService.buttonPress();
                  }
                  await themeProvider.toggleDarkMode();
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const Divider(),

              // Theme Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Color Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Theme Options
              ...AppTheme.values.map((theme) {
                return RadioListTile<AppTheme>(
                  title: Text(theme.displayName),
                  value: theme,
                  groupValue: themeProvider.currentTheme,
                  onChanged: (value) async {
                    if (value != null) {
                      if (themeProvider.hapticEnabled) {
                        await HapticFeedbackService.buttonPress();
                      }
                      await themeProvider.setTheme(value);
                    }
                  },
                  secondary: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? theme.darkColorScheme.primary
                          : theme.lightColorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),

              const Divider(),

              // Haptic Feedback Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

              // About Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const ListTile(
                title: Text('Japamala App'),
                subtitle: Text('Digital mantra counting for spiritual practice'),
              ),

              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
            ],
          );
        },
      ),
    );
  }
}
