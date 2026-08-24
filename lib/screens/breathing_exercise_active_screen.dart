import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/breathing_patterns.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import '../services/sound_service.dart';

class BreathingExerciseActiveScreen extends StatefulWidget {
  final BreathingPattern pattern;

  const BreathingExerciseActiveScreen({super.key, required this.pattern});

  @override
  State<BreathingExerciseActiveScreen> createState() =>
      _BreathingExerciseActiveScreenState();
}

class _BreathingExerciseActiveScreenState
    extends State<BreathingExerciseActiveScreen>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  bool _isPaused = false;
  bool _isFinished = false;

  /// Index into the pattern's active phases; -1 before the first breath, so
  /// the cycle opens on the inhale.
  int _phaseIndex = -1;
  int _completedCycles = 0;

  /// Wall-clock end of the current phase, so the countdown can't drift.
  DateTime? _phaseEndsAt;
  Duration _phaseRemaining = Duration.zero;
  Timer? _ticker;

  late int _targetCycles = widget.pattern.defaultCycles;
  DateTime? _startedAt;
  Duration _elapsedBeforePause = Duration.zero;

  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  bool _screenKeptAwake = false;

  /// Captured up front so a session can still be written while the screen is
  /// being torn down.
  late final SessionProvider _sessionProvider;

  /// Wall-clock start of the round, for the recorded session.
  DateTime? _sessionStartedAt;

  List<BreathPhase> get _phases => widget.pattern.activePhases;

  BreathPhase? get _currentPhase =>
      _phaseIndex >= 0 && _phaseIndex < _phases.length
      ? _phases[_phaseIndex]
      : null;

  /// Nadi Shodhana alternates sides each cycle.
  bool get _isLeftNostril => _completedCycles.isEven;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: widget.pattern.inhale,
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );
    _sessionProvider = context.read<SessionProvider>();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // Leaving part-way through still counts as practice.
    _recordSession(completed: false);
    _releaseScreen();
    _breathController.dispose();
    super.dispose();
  }

  /// Writes what was actually breathed. A round abandoned in its first cycle
  /// isn't practice, so nothing is recorded below one completed cycle.
  void _recordSession({required bool completed}) {
    final startedAt = _sessionStartedAt;
    if (startedAt == null || _completedCycles < 1) return;

    _sessionProvider.addSession(
      Session.breathing(
        patternId: widget.pattern.id,
        patternName: widget.pattern.name,
        cycles: _completedCycles,
        startTime: startedAt,
        endTime: DateTime.now(),
        completed: completed,
      ),
    );
    // Guard against the same round being written twice, e.g. finishing and
    // then leaving the screen.
    _sessionStartedAt = null;
  }

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

  // --- session control -------------------------------------------------------

  void _start() {
    setState(() {
      _isActive = true;
      _isPaused = false;
      _isFinished = false;
      _completedCycles = 0;
      _phaseIndex = -1;
      _startedAt = DateTime.now();
      _elapsedBeforePause = Duration.zero;
      _sessionStartedAt = DateTime.now();
    });
    _keepScreenAwake();
    _advancePhase();
  }

  void _stop({bool finished = false}) {
    _ticker?.cancel();
    _ticker = null;
    _breathController.stop();
    _releaseScreen();
    setState(() {
      _isActive = false;
      _isPaused = false;
      _isFinished = finished;
      _phaseIndex = -1;
      _phaseEndsAt = null;
      _phaseRemaining = Duration.zero;
    });
  }

  void _togglePause() {
    if (!_isActive) return;

    setState(() {
      if (_isPaused) {
        // Resume: push the phase deadline out by however long we were away.
        _isPaused = false;
        final remaining = _phaseRemaining;
        _phaseEndsAt = DateTime.now().add(remaining);
        _startedAt = DateTime.now();
        final phase = _currentPhase;
        if (phase == BreathPhase.inhale) {
          _breathController.forward();
        } else if (phase == BreathPhase.exhale) {
          _breathController.reverse();
        }
      } else {
        _isPaused = true;
        _elapsedBeforePause += DateTime.now().difference(_startedAt!);
        _breathController.stop();
      }
    });

    if (context.read<ThemeProvider>().hapticEnabled) {
      HapticFeedbackService.buttonPress();
    }
  }

  /// Moves to the next phase, counting a cycle each time the list wraps.
  void _advancePhase() {
    if (!_isActive) return;
    if (_phases.isEmpty) {
      _stop();
      return;
    }

    var next = _phaseIndex + 1;
    if (next >= _phases.length) {
      next = 0;
      if (_phaseIndex >= 0) {
        _completedCycles++;
        if (_completedCycles >= _targetCycles) {
          _finish();
          return;
        }
      }
    }

    final phase = _phases[next];
    final duration = widget.pattern.durationOf(phase);

    setState(() {
      _phaseIndex = next;
      _phaseEndsAt = DateTime.now().add(duration);
      _phaseRemaining = duration;
    });

    _animateFor(phase, duration);
    _signalPhase(phase);
    _startTicker();
  }

  /// The circle expands over the inhale and contracts over the exhale, taking
  /// exactly as long as the phase does; it holds its size through the holds.
  void _animateFor(BreathPhase phase, Duration duration) {
    switch (phase) {
      case BreathPhase.inhale:
        _breathController.duration = duration;
        _breathController.forward(from: _breathController.value);
        break;
      case BreathPhase.exhale:
        _breathController.duration = duration;
        _breathController.reverse(from: _breathController.value);
        break;
      case BreathPhase.holdIn:
      case BreathPhase.holdOut:
        _breathController.stop();
        break;
    }
  }

  void _signalPhase(BreathPhase phase) {
    final settings = context.read<ThemeProvider>();

    if (settings.hapticEnabled) {
      switch (phase) {
        case BreathPhase.inhale:
          HapticFeedbackService.vibrate(HapticType.light);
          break;
        case BreathPhase.exhale:
          HapticFeedbackService.vibrate(HapticType.medium);
          break;
        case BreathPhase.holdIn:
        case BreathPhase.holdOut:
          HapticFeedbackService.buttonPress();
          break;
      }
    }

    if (settings.soundEnabled) {
      switch (phase) {
        case BreathPhase.inhale:
          SoundService.cue(SoundService.cueInAsset);
          break;
        case BreathPhase.exhale:
          SoundService.cue(SoundService.cueOutAsset);
          break;
        case BreathPhase.holdIn:
        case BreathPhase.holdOut:
          SoundService.cue(SoundService.cueHoldAsset);
          break;
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    // Ticks faster than once a second so the countdown reads smoothly for
    // fractional phases like coherent breathing's 5.5 seconds.
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isActive || _isPaused) return;
      final endsAt = _phaseEndsAt;
      if (endsAt == null) return;

      final left = endsAt.difference(DateTime.now());
      if (left <= Duration.zero) {
        _advancePhase();
      } else {
        setState(() => _phaseRemaining = left);
      }
    });
  }

  void _finish() {
    _recordSession(completed: true);
    _stop(finished: true);

    final settings = context.read<ThemeProvider>();
    if (settings.hapticEnabled) HapticFeedbackService.sessionComplete();
    if (settings.soundEnabled) SoundService.bell();
  }

  Duration get _elapsed {
    if (_startedAt == null) return _elapsedBeforePause;
    if (_isPaused || !_isActive) return _elapsedBeforePause;
    return _elapsedBeforePause + DateTime.now().difference(_startedAt!);
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pattern = widget.pattern;
    final phase = _currentPhase;

    return Scaffold(
      appBar: AppBar(
        title: Text(pattern.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showTechnique,
            tooltip: 'How to do this',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isActive) _buildCyclePicker(context),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBreathCircle(context, phase),
                      const SizedBox(height: 32),
                      Text(
                        _isFinished
                            ? 'Complete'
                            : phase?.label.toUpperCase() ??
                                  (_isActive ? '' : 'READY'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        // Cross-fades so a new cue doesn't snap in mid-breath.
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          child: Text(
                            _instructionText(pattern, phase),
                            key: ValueKey<String>(
                              _instructionText(pattern, phase),
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                        ),
                      ),
                      if (pattern.alternateNostrils && _isActive) ...[
                        const SizedBox(height: 12),
                        Chip(
                          avatar: Icon(
                            _isLeftNostril
                                ? Icons.arrow_back
                                : Icons.arrow_forward,
                            size: 18,
                          ),
                          label: Text(
                            _isLeftNostril ? 'Left nostril' : 'Right nostril',
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_isActive || _isFinished) _buildSessionStats(context),
                    ],
                  ),
                ),
              ),
            ),
            _buildControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathCircle(BuildContext context, BreathPhase? phase) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring showing how far through the whole session we are.
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: _targetCycles == 0
                  ? 0
                  : (_completedCycles / _targetCycles).clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                scheme.tertiary.withValues(alpha: 0.7),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathAnimation.value,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.18),
                    border: Border.all(color: scheme.primary, width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _phaseIcon(phase),
                          size: 36,
                          color: scheme.primary,
                        ),
                        if (_isActive && !_isPaused) ...[
                          const SizedBox(height: 4),
                          Text(
                            _phaseRemaining.inMilliseconds <= 0
                                ? ''
                                : '${(_phaseRemaining.inMilliseconds / 1000).ceil()}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                        ],
                        if (_isPaused)
                          Text(
                            'Paused',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _phaseIcon(BreathPhase? phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return Icons.arrow_upward;
      case BreathPhase.exhale:
        return Icons.arrow_downward;
      case BreathPhase.holdIn:
      case BreathPhase.holdOut:
        return Icons.pause;
      case null:
        return Icons.circle_outlined;
    }
  }

  String _instructionText(BreathingPattern pattern, BreathPhase? phase) {
    if (_isFinished) {
      return 'Well done. Notice how you feel before moving on.';
    }
    if (!_isActive) {
      return 'Get comfortable, then begin when you are ready.';
    }
    if (_isPaused) return 'Paused — resume when you are ready.';
    if (phase == null) return '';
    return pattern.cueFor(phase);
  }

  Widget _buildCyclePicker(BuildContext context) {
    final pattern = widget.pattern;
    final estimate = pattern.estimatedDuration(_targetCycles);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cycles', style: Theme.of(context).textTheme.titleSmall),
              Text(
                '$_targetCycles  ·  about ${_formatDuration(estimate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _targetCycles.toDouble(),
            min: 3,
            max: 40,
            divisions: 37,
            label: '$_targetCycles',
            onChanged: (value) => setState(() => _targetCycles = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats(BuildContext context) {
    return Wrap(
      spacing: 24,
      alignment: WrapAlignment.center,
      children: [
        _stat(context, 'Cycles', '$_completedCycles / $_targetCycles'),
        _stat(context, 'Elapsed', _formatDuration(_elapsed)),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isActive)
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isFinished ? 'Practise again' : 'Begin'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: _togglePause,
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(_isPaused ? 'Resume' : 'Pause'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                _recordSession(completed: false);
                _stop();
              },
              icon: const Icon(Icons.stop),
              label: const Text('Finish'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTechnique() {
    final pattern = widget.pattern;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              pattern.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (pattern.sanskritName != null)
              Text(
                pattern.sanskritName!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            const SizedBox(height: 16),
            Text('Rhythm', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              '${pattern.rhythm} seconds',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Good for', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              pattern.benefit,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('How to do it', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              pattern.technique,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}
