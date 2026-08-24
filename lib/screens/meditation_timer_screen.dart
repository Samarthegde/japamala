import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import '../services/sound_service.dart';

class MeditationTimerScreen extends StatefulWidget {
  const MeditationTimerScreen({super.key});

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen> {
  static const List<int> _durations = [5, 10, 15, 30]; // minutes
  int _selectedDuration = 5; // default 5 minutes
  int _remainingSeconds = 5 * 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;

  /// Wall-clock instant the session ends. Deriving the countdown from this
  /// rather than counting ticks keeps the timer honest across tick drift and
  /// periods where the process was suspended.
  DateTime? _endTime;

  bool _screenKeptAwake = false;

  late final SessionProvider _sessionProvider;

  /// When the current run of the timer began, for the recorded session.
  DateTime? _sittingStartedAt;

  /// A sitting shorter than this is a mis-tap, not practice.
  static const Duration _minimumSitting = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _sessionProvider = context.read<SessionProvider>();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Leaving mid-sit still counts, as long as it was long enough to mean it.
    _recordSitting(completed: false);
    _releaseScreen();
    super.dispose();
  }

  void _recordSitting({required bool completed}) {
    final startedAt = _sittingStartedAt;
    if (startedAt == null) return;

    final now = DateTime.now();
    if (now.difference(startedAt) < _minimumSitting) {
      _sittingStartedAt = null;
      return;
    }

    _sessionProvider.addSession(
      Session.meditation(
        startTime: startedAt,
        endTime: now,
        completed: completed,
      ),
    );
    // Guard against writing the same sitting twice.
    _sittingStartedAt = null;
  }

  /// Held only while the timer runs, so a paused timer doesn't burn battery.
  Future<void> _keepScreenAwake() async {
    if (_screenKeptAwake || !context.read<ThemeProvider>().keepScreenOn) return;
    _screenKeptAwake = true;
    await WakelockPlus.enable();
  }

  Future<void> _releaseScreen() async {
    if (!_screenKeptAwake) return;
    _screenKeptAwake = false;
    await WakelockPlus.disable();
  }

  void _selectDuration(int minutes) {
    _timer?.cancel();
    setState(() {
      _selectedDuration = minutes;
      _remainingSeconds = minutes * 60;
      _isRunning = false;
      _isCompleted = false;
      _endTime = null;
    });
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    _timer?.cancel();
    _endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    // Pausing and resuming continues the same sitting.
    _sittingStartedAt ??= DateTime.now();
    setState(() {
      _isRunning = true;
      _isCompleted = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _keepScreenAwake();
  }

  void _onTick() {
    final endTime = _endTime;
    if (endTime == null) return;

    final millisecondsLeft = endTime.difference(DateTime.now()).inMilliseconds;
    if (millisecondsLeft <= 0) {
      setState(() {
        _remainingSeconds = 0;
      });
      _completeTimer();
    } else {
      setState(() {
        _remainingSeconds = (millisecondsLeft / 1000).ceil();
      });
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    _releaseScreen();
    setState(() {
      _isRunning = false;
      _endTime = null;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _recordSitting(completed: false);
    _releaseScreen();
    setState(() {
      _remainingSeconds = _selectedDuration * 60;
      _isRunning = false;
      _isCompleted = false;
      _endTime = null;
    });
  }

  void _completeTimer() {
    if (_isCompleted) return;

    _timer?.cancel();
    _recordSitting(completed: true);
    _releaseScreen();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _endTime = null;
    });

    final settings = context.read<ThemeProvider>();
    if (settings.hapticEnabled) {
      HapticFeedbackService.sessionComplete();
    }
    if (settings.soundEnabled) {
      SoundService.bell();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Meditation Complete'),
        content: const Text('Great job! Your meditation session has finished.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _resetTimer();
            },
            child: const Text('Start Another'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTimer,
            tooltip: 'Reset Timer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Duration Selection
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Duration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _durations.map((duration) {
                    final isSelected = duration == _selectedDuration;
                    return ElevatedButton(
                      onPressed: _isRunning
                          ? null
                          : () => _selectDuration(duration),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text('$duration min'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Timer Display
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular Progress Indicator
                  Container(
                    width: 250,
                    height: 250,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: _isCompleted
                                ? 1.0
                                : (_remainingSeconds /
                                      (_selectedDuration * 60)),
                            strokeWidth: 8,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isCompleted
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          width: 180,
                          height: 180,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isCompleted
                                    ? Icons.check_circle
                                    : Icons.self_improvement,
                                size: 48,
                                color: _isCompleted
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatTime(_remainingSeconds),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        color: _isCompleted
                                            ? Colors.green
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isCompleted
                                      ? 'Complete!'
                                      : _isRunning
                                      ? 'Meditating...'
                                      : 'Ready to begin',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isCompleted) ...[
                        ElevatedButton.icon(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_isRunning ? 'Pause' : 'Start'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Gentle Reminder Text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _isRunning
                          ? 'Take deep, calming breaths. Focus on your breath or a peaceful mantra.'
                          : _isCompleted
                          ? 'Well done! Take a moment to notice how you feel.'
                          : 'Find a comfortable position. Set your intention for this meditation.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
