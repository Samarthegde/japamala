import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mantra.dart';
import '../models/session.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';

class CounterScreen extends StatefulWidget {
  final Mantra mantra;

  const CounterScreen({super.key, required this.mantra});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late Mantra _currentMantra;
  DateTime? _sessionStartTime;
  bool _isPaused = false;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  @override
  void initState() {
    super.initState();
    _currentMantra = widget.mantra;
    _sessionStartTime = DateTime.now();
  }

  void _incrementCounter() async {
    if (_currentMantra.currentCount < _currentMantra.targetCount) {
      context.read<MantraProvider>().incrementCount(_currentMantra.id);

      // Haptic feedback for bead counting
      if (context.read<ThemeProvider>().hapticEnabled) {
        await HapticFeedbackService.beadCount();
      }

      setState(() {
        _currentMantra = _currentMantra.copyWith(
          currentCount: _currentMantra.currentCount + 1,
        );
      });

      // Check if completed
      if (_currentMantra.currentCount + 1 >= _currentMantra.targetCount) {
        _completeSession();
      }
    }
  }

  void _resetCounter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Counter'),
        content: const Text('Are you sure you want to reset the counter to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MantraProvider>().resetCount(_currentMantra.id);
              setState(() {
                _currentMantra = _currentMantra.copyWith(currentCount: 0);
                _sessionStartTime = DateTime.now();
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _completeSession() async {
    // TODO: Re-enable session saving when SessionProvider is fixed
    // Save completed session
    // if (_sessionStartTime != null) {
    //   final session = Session.create(
    //     mantraId: _currentMantra.id,
    //     count: _currentMantra.currentCount,
    //     startTime: _sessionStartTime!,
    //     endTime: DateTime.now(),
    //     completed: true,
    //   );
    //   context.read<SessionProvider>().addSession(session);
    // }

    // Haptic feedback for completion
    if (context.read<ThemeProvider>().hapticEnabled) {
      await HapticFeedbackService.sessionComplete();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Session completed!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveIncompleteSession() {
    // TODO: Re-enable session saving when SessionProvider is fixed
    // Save incomplete session when leaving
    // if (_sessionStartTime != null && _currentMantra.currentCount > 0) {
    //   final session = Session.create(
    //     mantraId: _currentMantra.id,
    //     count: _currentMantra.currentCount,
    //     startTime: _sessionStartTime!,
    //     endTime: DateTime.now(),
    //     completed: false,
    //   );
    //   context.read<SessionProvider>().addSession(session);
    // }
  }

  @override
  void dispose() {
    _saveIncompleteSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentMantra.progress;
    final isCompleted = _currentMantra.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentMantra.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'Reset Counter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${_currentMantra.currentCount}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/ ${_currentMantra.targetCount}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          size: 60,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isCompleted ? 'Completed!' : '${(progress * 100).round()}% Complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          // Counter Button
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: isCompleted ? null : _incrementCounter,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.touch_app,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),

          // Info Section
          if (_currentMantra.description != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _currentMantra.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
