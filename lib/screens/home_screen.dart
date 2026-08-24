import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mantra.dart';
import '../models/mantra_presets.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import '../widgets/animations.dart';
import 'create_mantra_screen.dart';
import 'counter_screen.dart';
import 'calendar_screen.dart';
import 'commitments_screen.dart';
import 'insights_screen.dart';
import 'mantra_library_screen.dart';
import 'session_history_screen.dart';
import 'settings_screen.dart';
import 'gratitude_journal_screen.dart';
import 'meditation_timer_screen.dart';
import 'breathing_exercises_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Navigation used to `await` the haptic first, which put a BuildContext
  /// across an async gap on every menu item. The buzz doesn't need awaiting.
  void _open(BuildContext context, Widget screen) {
    if (context.read<ThemeProvider>().hapticEnabled) {
      HapticFeedbackService.buttonPress();
    }
    Navigator.push(context, AppPageRoute<void>(page: screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japamala'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _open(context, const CalendarScreen()),
            tooltip: 'Practice Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _open(context, const CreateMantraScreen()),
            tooltip: 'Create Mantra',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer<MantraProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.mantras.isEmpty) {
            return _buildEmptyState(context, provider);
          }

          return Column(
            children: [
              const FadeSlideIn(child: SizedBox.shrink()),
              _buildStatsCard(context, provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.mantras.length,
                  itemBuilder: (context, index) {
                    return _buildMantraCard(
                      context,
                      provider,
                      provider.mantras[index],
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

  Widget _buildDrawer(BuildContext context) {
    final destinations = <({IconData icon, String label, Widget? screen})>[
      (icon: Icons.home, label: 'Home', screen: null),
      (
        icon: Icons.calendar_today,
        label: 'Calendar',
        screen: const CalendarScreen(),
      ),
      (
        icon: Icons.menu_book,
        label: 'Mantra Library',
        screen: const MantraLibraryScreen(),
      ),
      (icon: Icons.flag, label: 'Sankalpa', screen: const CommitmentsScreen()),
      (icon: Icons.insights, label: 'Insights', screen: const InsightsScreen()),
      (
        icon: Icons.history,
        label: 'Session History',
        screen: const SessionHistoryScreen(),
      ),
      (
        icon: Icons.book,
        label: 'Gratitude Journal',
        screen: const GratitudeJournalScreen(),
      ),
      (
        icon: Icons.timer,
        label: 'Meditation Timer',
        screen: const MeditationTimerScreen(),
      ),
      (
        icon: Icons.air,
        label: 'Breathing Exercises',
        screen: const BreathingExercisesScreen(),
      ),
      (icon: Icons.settings, label: 'Settings', screen: const SettingsScreen()),
    ];

    return Drawer(
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          for (final destination in destinations)
            ListTile(
              leading: Icon(destination.icon),
              title: Text(destination.label),
              onTap: () {
                Navigator.pop(context);
                final screen = destination.screen;
                if (screen != null) _open(context, screen);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, MantraProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<SessionProvider>(
          builder: (context, sessionProvider, child) {
            return Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.local_fire_department,
                    '${sessionProvider.currentStreak}',
                    'Streak',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.check_circle,
                    '${provider.totalMantrasCompleted}',
                    'Completed',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.history,
                    '${sessionProvider.totalSessions}',
                    'Sessions',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.blur_circular,
                    '${sessionProvider.totalBeads}',
                    'Beads',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MantraProvider provider) {
    return FadeSlideIn(
      offset: 24,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.self_improvement,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _open(context, const CreateMantraScreen()),
                icon: const Icon(Icons.add),
                label: const Text('Create Mantra'),
              ),
              const SizedBox(height: 32),
              Text(
                'Or start with a common one',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: MantraPreset.all.map((preset) {
                  return ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(preset.name),
                    onPressed: () {
                      if (context.read<ThemeProvider>().hapticEnabled) {
                        HapticFeedbackService.buttonPress();
                      }
                      provider.addMantra(preset.toMantra());
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMantraCard(
    BuildContext context,
    MantraProvider provider,
    Mantra mantra,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: mantra.isDaily
            ? const Icon(Icons.wb_sunny, color: Colors.orange, size: 24)
            : null,
        title: Row(
          children: [
            Flexible(child: Text(mantra.name, overflow: TextOverflow.ellipsis)),
            if (mantra.isDaily) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
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
            Hero(
              tag: 'mala-${mantra.id}',
              // The two ends are different shapes, so fade between them
              // rather than trying to morph one into the other.
              flightShuttleBuilder: (_, animation, __, ___, ____) =>
                  FadeTransition(
                    opacity: animation,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: mantra.progress,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: mantra.progress,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mantra options',
              onSelected: (value) {
                if (value == 'edit') {
                  _open(context, CreateMantraScreen(mantra: mantra));
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, provider, mantra);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _open(context, CounterScreen(mantra: mantra)),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedCount(
            value: int.tryParse(value) ?? 0,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    MantraProvider provider,
    Mantra mantra,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Mantra'),
          content: Text(
            'Are you sure you want to delete "${mantra.name}"? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Capture before the await so nothing reaches across the gap.
                final messenger = ScaffoldMessenger.of(context);
                final hapticEnabled = context
                    .read<ThemeProvider>()
                    .hapticEnabled;
                // A detached copy, so Undo can put it straight back.
                final deleted = mantra.copyWith();

                Navigator.of(dialogContext).pop();
                await provider.deleteMantra(mantra.id);
                if (hapticEnabled) {
                  HapticFeedbackService.buttonPress();
                }

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${deleted.name} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => provider.addMantra(deleted),
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
