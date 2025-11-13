import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mantra_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import 'create_mantra_screen.dart';
import 'counter_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'gratitude_journal_screen.dart';
import 'meditation_timer_screen.dart';
import 'breathing_exercises_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japamala'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              if (context.read<ThemeProvider>().hapticEnabled) {
                await HapticFeedbackService.buttonPress();
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
              );
            },
            tooltip: 'Practice Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (context.read<ThemeProvider>().hapticEnabled) {
                await HapticFeedbackService.buttonPress();
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateMantraScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Japamala',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digital mantra counting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () async {
                if (context.read<ThemeProvider>().hapticEnabled) {
                  await HapticFeedbackService.buttonPress();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Gratitude Journal'),
              onTap: () async {
                if (context.read<ThemeProvider>().hapticEnabled) {
                  await HapticFeedbackService.buttonPress();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GratitudeJournalScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Meditation Timer'),
              onTap: () async {
                if (context.read<ThemeProvider>().hapticEnabled) {
                  await HapticFeedbackService.buttonPress();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeditationTimerScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.air),
              title: const Text('Breathing Exercises'),
              onTap: () async {
                if (context.read<ThemeProvider>().hapticEnabled) {
                  await HapticFeedbackService.buttonPress();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BreathingExercisesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () async {
                if (context.read<ThemeProvider>().hapticEnabled) {
                  await HapticFeedbackService.buttonPress();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<MantraProvider>(
        builder: (context, provider, child) {
          debugPrint('Building home screen with ${provider.mantras.length} mantras');
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.mantras.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No mantras yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first mantra to begin your practice',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (context.read<ThemeProvider>().hapticEnabled) {
                        await HapticFeedbackService.buttonPress();
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateMantraScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Mantra'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Statistics Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: _buildStatItem(
                      context,
                      Icons.check_circle,
                      '${provider.totalMantrasCompleted}',
                      'Completed',
                    ),
                  ),
                ),
              ),

              // Mantras List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.mantras.length,
                  itemBuilder: (context, index) {
                    final mantra = provider.mantras[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: mantra.isDaily
                            ? Icon(
                                Icons.wb_sunny,
                                color: Colors.orange,
                                size: 24,
                              )
                            : null,
                        title: Row(
                          children: [
                            Text(mantra.name),
                            if (mantra.isDaily) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Daily',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${mantra.currentCount} / ${mantra.targetCount}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: mantra.progress,
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                if (context.read<ThemeProvider>().hapticEnabled) {
                                  await HapticFeedbackService.buttonPress();
                                }
                                _showDeleteConfirmation(context, provider, mantra);
                              },
                              tooltip: 'Delete Mantra',
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (context.read<ThemeProvider>().hapticEnabled) {
                            await HapticFeedbackService.buttonPress();
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CounterScreen(mantra: mantra),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, MantraProvider provider, dynamic mantra) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Mantra'),
          content: Text('Are you sure you want to delete "${mantra.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await provider.deleteMantra(mantra.id);
                if (context.read<ThemeProvider>().hapticEnabled) {
                  await HapticFeedbackService.buttonPress();
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${mantra.name} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        // Note: In a full implementation, you'd want to implement undo functionality
                        // For now, we'll just show that the delete was successful
                      },
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
