import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/breathing_patterns.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';

class BreathingExerciseActiveScreen extends StatefulWidget {
  final BreathingPattern selectedPattern;

  const BreathingExerciseActiveScreen({
    super.key,
    required this.selectedPattern,
  });

  @override
  State<BreathingExerciseActiveScreen> createState() => _BreathingExerciseActiveScreenState();
}

class _BreathingExerciseActiveScreenState extends State<BreathingExerciseActiveScreen>
    with TickerProviderStateMixin {
  bool _isActive = false;
  String _currentPhase = 'ready';
  int _phaseTime = 0;
  Timer? _timer;
  int _cycleCount = 0;

  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _currentPhase = 'inhale';
      _phaseTime = widget.selectedPattern.phases['inhale']!;
      _cycleCount = 0;
    });

    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    final phases = widget.selectedPattern.phases;
    int phaseIndex = 0;
    final phaseOrder = ['inhale', 'hold', 'exhale', 'pause'];

    void nextPhase() {
      if (!_isActive) return;

      phaseIndex++;
      if (phaseIndex >= phaseOrder.length) {
        phaseIndex = 0;
        setState(() {
          _cycleCount++;
        });
      }

      final phase = phaseOrder[phaseIndex];
      final duration = phases[phase]!;

      if (duration > 0) {
        setState(() {
          _currentPhase = phase;
          _phaseTime = duration;
        });

        // Animate breathing
        if (phase == 'inhale') {
          _breathController.forward();
        } else if (phase == 'exhale') {
          _breathController.reverse();
        }

        // Haptic feedback for phase changes
        if (context.read<ThemeProvider>().hapticEnabled) {
          HapticFeedbackService.beadCount();
        }

        _timer = Timer(Duration(seconds: 1), () {
          if (_isActive) {
            _countdownPhase(duration - 1, phase, nextPhase);
          }
        });
      } else {
        nextPhase();
      }
    }

    nextPhase();
  }

  void _countdownPhase(int remaining, String phase, VoidCallback onComplete) {
    if (!_isActive || remaining <= 0) {
      onComplete();
      return;
    }

    setState(() {
      _phaseTime = remaining;
    });

    _timer = Timer(const Duration(seconds: 1), () {
      _countdownPhase(remaining - 1, phase, onComplete);
    });
  }

  void _stopBreathing() {
    setState(() {
      _isActive = false;
      _currentPhase = 'ready';
      _phaseTime = 0;
    });
    _timer?.cancel();
    _breathController.stop();
  }

  String _getPhaseInstruction() {
    switch (_currentPhase) {
      case 'inhale':
        return 'Breathe in slowly...';
      case 'hold':
        return 'Hold your breath...';
      case 'exhale':
        return 'Breathe out slowly...';
      case 'pause':
        return 'Pause...';
      default:
        return 'Get comfortable and begin when ready';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedPattern.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.selectedPattern.displayName),
                  content: Text(widget.selectedPattern.description),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Breathing Circle
            Container(
              width: 200,
              height: 200,
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _breathAnimation,
                builder: (context, child) {
                  final scale = _breathAnimation.value.clamp(0.7, 1.3);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _currentPhase == 'inhale'
                            ? Icons.arrow_upward
                            : _currentPhase == 'exhale'
                                ? Icons.arrow_downward
                                : Icons.circle,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // Phase Display
            Text(
              _currentPhase.toUpperCase(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Countdown Timer
            if (_isActive)
              Text(
                _phaseTime.toString(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w300,
                ),
              ),

            const SizedBox(height: 16),

            // Instruction Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _getPhaseInstruction(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Cycle Counter
            if (_cycleCount > 0)
              Text(
                'Cycles completed: $_cycleCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),

            const SizedBox(height: 40),

            // Control Button
            ElevatedButton.icon(
              onPressed: _isActive ? _stopBreathing : _startBreathing,
              icon: Icon(_isActive ? Icons.stop : Icons.play_arrow),
              label: Text(_isActive ? 'Stop Breathing' : 'Start Breathing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Pattern Details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    widget.selectedPattern.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedPattern.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
