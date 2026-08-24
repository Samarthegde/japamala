import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/breathing_patterns.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import '../widgets/animations.dart';
import 'breathing_exercise_active_screen.dart';

class BreathingExercisesScreen extends StatefulWidget {
  const BreathingExercisesScreen({super.key});

  @override
  State<BreathingExercisesScreen> createState() =>
      _BreathingExercisesScreenState();
}

class _BreathingExercisesScreenState extends State<BreathingExercisesScreen> {
  /// Null means "show everything"; otherwise filter to one goal.
  BreathingGoal? _goal;

  @override
  Widget build(BuildContext context) {
    final patterns = _goal == null
        ? BreathingPattern.all
        : BreathingPattern.all
              .where((pattern) => pattern.goal == _goal)
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercises')),
      body: Column(
        children: [
          // People pick a breathing exercise by what they want from it, not
          // by its name.
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _goal == null,
                    onSelected: (_) => setState(() => _goal = null),
                  ),
                ),
                for (final goal in BreathingGoal.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: FilterChip(
                      avatar: Icon(goal.icon, size: 18),
                      label: Text(goal.label),
                      selected: _goal == goal,
                      onSelected: (_) => setState(() => _goal = goal),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: patterns.length,
              itemBuilder: (context, index) => FadeSlideIn(
                delay: FadeSlideIn.stagger(index),
                child: _PatternCard(pattern: patterns[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final BreathingPattern pattern;

  const _PatternCard({required this.pattern});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (context.read<ThemeProvider>().hapticEnabled) {
            HapticFeedbackService.buttonPress();
          }
          Navigator.push(
            context,
            AppPageRoute<void>(
              page: BreathingExerciseActiveScreen(pattern: pattern),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(pattern.icon, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pattern.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (pattern.sanskritName != null)
                          Text(
                            pattern.sanskritName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: scheme.primary,
                                ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          pattern.benefit,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.75),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _tag(context, '${pattern.rhythm}s', scheme.primary),
                  _tag(
                    context,
                    '~${_estimate(pattern)}',
                    scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  _tag(context, pattern.level.label, pattern.level.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _estimate(BreathingPattern pattern) {
    final duration = pattern.estimatedDuration(pattern.defaultCycles);
    final minutes = (duration.inSeconds / 60).round();
    return minutes <= 1 ? '1 min' : '$minutes min';
  }

  Widget _tag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
