import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/breathing_patterns.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import 'breathing_exercise_active_screen.dart';

class BreathingExercisesScreen extends StatelessWidget {
  const BreathingExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Exercises'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a Breathing Pattern',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a pattern to begin your guided breathing exercise',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: BreathingPattern.values.map((pattern) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        if (context.read<ThemeProvider>().hapticEnabled) {
                          await HapticFeedbackService.buttonPress();
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BreathingExerciseActiveScreen(
                              selectedPattern: pattern,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    pattern == BreathingPattern.fourSevenEight
                                        ? Icons.nightlight_round
                                        : pattern == BreathingPattern.boxBreathing
                                            ? Icons.grid_4x4
                                            : Icons.waves,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pattern.displayName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pattern.description,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Phase indicators
                            Row(
                              children: pattern.phases.entries.map((entry) {
                                if (entry.value == 0) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.key}: ${entry.value}s',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Each pattern includes haptic feedback to guide your breathing rhythm.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
