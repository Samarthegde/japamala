import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/mantra.dart';
import '../models/session.dart';
import '../providers/commitment_provider.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';
import '../services/sound_service.dart';
import '../services/volume_key_service.dart';
import '../widgets/mala_ring.dart';
import '../widgets/swipe_coach.dart';
import 'reflection_sheet.dart';

class CounterScreen extends StatefulWidget {
  final Mantra mantra;

  const CounterScreen({super.key, required this.mantra});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with TickerProviderStateMixin {
  /// How far the thumb must travel for a pull to register. One pull moves one
  /// bead — the same as on a real mala — no matter how far it is carried.
  static const double _swipeThreshold = 44;

  /// Captured in initState so [dispose] can record an unfinished sitting
  /// without reaching for a BuildContext that is being torn down.
  late final MantraProvider _mantraProvider;
  late final SessionProvider _sessionProvider;
  late final ThemeProvider _themeProvider;
  late final CommitmentProvider _commitmentProvider;

  /// A "sitting" is one stretch of counting on this screen.
  DateTime _sittingStartTime = DateTime.now();
  int _sittingStartCount = 0;

  StreamSubscription<String>? _volumeKeys;
  bool _screenKeptAwake = false;

  bool _isPaused = false;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pauseStartedAt;

  Timer? _ticker;
  DateTime? _timerEndsAt;
  Duration _timerRemaining = Duration.zero;
  static const List<int> _timerOptions = [5, 10, 15, 20, 30, 45];

  /// Travel of the pull in progress, in logical pixels.
  double _dragOffset = 0;

  /// One bead per pull: set once a pull registers, cleared on release.
  bool _gestureCounted = false;

  /// Drives the bead back to rest. Unbounded so the spring may overshoot
  /// slightly before settling, which reads as weight rather than a slide.
  late final AnimationController _settleController;

  /// A mala has some give to it; a linear glide back felt mechanical.
  static const SpringDescription _settleSpring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 26,
  );

  /// Pulse played on the bead as it registers.
  late final AnimationController _popController;

  /// Shown until the first bead is pulled, so the gesture is discoverable.
  bool _showCoach = false;

  /// Chrome starts hidden: nothing should compete with the beads.
  bool _showChrome = false;
  Timer? _chromeTimer;

  @override
  void initState() {
    super.initState();
    _mantraProvider = context.read<MantraProvider>();
    _sessionProvider = context.read<SessionProvider>();
    _themeProvider = context.read<ThemeProvider>();
    _commitmentProvider = context.read<CommitmentProvider>();
    _sittingStartCount = _currentCount;

    _settleController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _dragOffset = _settleController.value);
      });

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    // Full screen: system bars would sit right where the loop runs.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _showCoach =
        !_themeProvider.seenSwipeCoach &&
        _themeProvider.counterGesture == CounterGesture.swipe;

    _keepScreenAwake();
    _listenForVolumeKeys();
  }

  void _dismissCoach() {
    if (!_showCoach) return;
    setState(() => _showCoach = false);
    _themeProvider.markSwipeCoachSeen();
  }

  @override
  void dispose() {
    _chromeTimer?.cancel();
    _ticker?.cancel();
    _settleController.dispose();
    _popController.dispose();
    _volumeKeys?.cancel();
    VolumeKeyService.setCaptureEnabled(false);
    if (_screenKeptAwake) WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _saveSitting(completed: false);
    super.dispose();
  }

  Future<void> _keepScreenAwake() async {
    if (!_themeProvider.keepScreenOn) return;
    _screenKeptAwake = true;
    await WakelockPlus.enable();
  }

  void _listenForVolumeKeys() {
    if (!_themeProvider.volumeKeyCounting || !VolumeKeyService.isSupported) {
      return;
    }
    VolumeKeyService.setCaptureEnabled(true);
    _volumeKeys = VolumeKeyService.presses.listen((_) {
      _countBead();
      _popController.forward(from: 0);
    });
  }

  Mantra _mantraOf(BuildContext context) =>
      context.watch<MantraProvider>().getMantraById(widget.mantra.id) ??
      widget.mantra;

  Mantra get _mantra =>
      _mantraProvider.getMantraById(widget.mantra.id) ?? widget.mantra;

  int get _currentCount => _mantra.currentCount;

  // --- chrome ----------------------------------------------------------------

  void _toggleChrome() {
    setState(() => _showChrome = !_showChrome);
    _chromeTimer?.cancel();
    if (_showChrome) _scheduleChromeHide();
  }

  void _keepChromeAlive() {
    if (!_showChrome) return;
    _chromeTimer?.cancel();
    _scheduleChromeHide();
  }

  void _scheduleChromeHide() {
    _chromeTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showChrome = false);
    });
  }

  // --- the pull --------------------------------------------------------------

  void _onDragStart(DragStartDetails details) {
    _settleController.stop();
    _dismissCoach();
    setState(() {
      _gestureCounted = false;
      _dragOffset = 0;
    });
  }

  /// One pull, one bead. Once a pull has registered it is spent, so carrying
  /// the thumb further down the screen cannot run the count away.
  void _onDragUpdate(DragUpdateDetails details) {
    if (_isPaused || _gestureCounted) return;

    _dragOffset += details.delta.dy;

    if (_dragOffset >= _swipeThreshold) {
      _registerPull(forward: true);
    } else if (_dragOffset <= -_swipeThreshold) {
      _registerPull(forward: false);
    } else {
      setState(() {});
    }
  }

  void _registerPull({required bool forward}) {
    _gestureCounted = true;
    _dismissCoach();
    if (forward) {
      _countBead();
    } else {
      _undoBead();
    }
    // The bead has arrived at the thumb; the loop rests until the next pull.
    setState(() => _dragOffset = 0);
    _popController.forward(from: 0);
  }

  void _onDragEnd() {
    _gestureCounted = false;
    if (_dragOffset == 0) return;

    // Let a part-finished pull spring back rather than leaving the loop askew.
    _settleController.value = _dragOffset;
    _settleController.animateWith(
      SpringSimulation(_settleSpring, _dragOffset, 0, 0),
    );
  }

  void _countBead() {
    if (_isPaused) return;

    final mantra = _mantra;
    if (mantra.isCompleted) return;

    final newCount = mantra.currentCount + 1;
    final justCompleted = newCount >= mantra.targetCount;
    final finishedRound =
        !justCompleted &&
        mantra.usesRounds &&
        newCount % mantra.beadsPerRound! == 0;

    _mantraProvider.incrementCount(mantra.id);

    if (_themeProvider.hapticEnabled) {
      if (justCompleted) {
        HapticFeedbackService.sessionComplete();
      } else if (finishedRound) {
        HapticFeedbackService.mantraComplete();
      } else {
        HapticFeedbackService.beadCount();
      }
    }

    if (finishedRound) _announceRound(newCount ~/ mantra.beadsPerRound!);
    if (justCompleted) _completeSession();
  }

  void _undoBead() {
    if (_currentCount <= 0) return;
    _mantraProvider.decrementCount(widget.mantra.id);
    if (_themeProvider.hapticEnabled) {
      HapticFeedbackService.buttonPress();
    }
  }

  void _announceRound(int round) {
    if (_themeProvider.soundEnabled) SoundService.bell();
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('📿 Mala $round complete'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _completeSession() {
    _saveSitting(completed: true);
    if (_themeProvider.soundEnabled) SoundService.bell();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 Session completed!'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reflect',
          onPressed: () => _openReflection(_mantra.name),
        ),
      ),
    );
  }

  /// The journal already knows how to show `After <mantra> practice`; this is
  /// what finally gives it something to show.
  void _openReflection(String mantraName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ReflectionSheet(mantraName: mantraName),
    );
  }

  // --- sitting ---------------------------------------------------------------

  void _saveSitting({required bool completed}) {
    final beads = _currentCount - _sittingStartCount;
    if (beads <= 0) return;

    _sessionProvider.addSession(
      Session.create(
        mantraId: widget.mantra.id,
        count: beads,
        // Shifting the start by the paused total makes the recorded duration
        // the time actually spent counting.
        startTime: _sittingStartTime.add(_pausedTotal),
        endTime: DateTime.now(),
        completed: completed,
      ),
    );

    _sittingStartTime = DateTime.now();
    _sittingStartCount = _currentCount;
    _pausedTotal = Duration.zero;

    _commitmentProvider.markCompletedIfReached(_sessionProvider.sessions);
  }

  // --- pause & timer ---------------------------------------------------------

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        final pausedFor = DateTime.now().difference(_pauseStartedAt!);
        _pausedTotal += pausedFor;
        _pauseStartedAt = null;
        _isPaused = false;
        if (_timerEndsAt != null) {
          _timerEndsAt = _timerEndsAt!.add(pausedFor);
        }
      } else {
        _pauseStartedAt = DateTime.now();
        _isPaused = true;
      }
    });
    if (_themeProvider.hapticEnabled) HapticFeedbackService.buttonPress();
    _keepChromeAlive();
  }

  void _chooseTimer() {
    _keepChromeAlive();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Practise for a set time'),
            ),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: _timerOptions
                  .map(
                    (minutes) => ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _startTimer(Duration(minutes: minutes));
                      },
                    ),
                  )
                  .toList(),
            ),
            if (_timerEndsAt != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _stopTimer();
                  },
                  icon: const Icon(Icons.timer_off),
                  label: const Text('Cancel timer'),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _startTimer(Duration duration) {
    _ticker?.cancel();
    setState(() {
      _timerEndsAt = DateTime.now().add(duration);
      _timerRemaining = duration;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final endsAt = _timerEndsAt;
      if (endsAt == null || _isPaused) return;

      final left = endsAt.difference(DateTime.now());
      if (left.isNegative || left.inSeconds <= 0) {
        _onTimerFinished();
      } else {
        setState(() => _timerRemaining = left);
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _timerEndsAt = null;
      _timerRemaining = Duration.zero;
    });
  }

  void _onTimerFinished() {
    _stopTimer();
    _saveSitting(completed: false);

    if (_themeProvider.hapticEnabled) HapticFeedbackService.sessionComplete();
    if (_themeProvider.soundEnabled) SoundService.bell();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Time complete'),
        content: Text(
          'Your timed practice has finished. '
          'Counted $_currentCount so far.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep counting'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    _keepChromeAlive();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Counter'),
        content: const Text('Are you sure you want to reset the counter to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _saveSitting(completed: false);
              _mantraProvider.resetCount(widget.mantra.id);
              setState(() {
                _sittingStartTime = DateTime.now();
                _sittingStartCount = 0;
                _dragOffset = 0;
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // --- display helpers -------------------------------------------------------

  int _headlineCount(Mantra mantra) {
    if (!mantra.usesRounds) return mantra.currentCount;
    if (mantra.currentCount > 0 && mantra.beadsInCurrentRound == 0) {
      return mantra.beadsPerRound!;
    }
    return mantra.beadsInCurrentRound;
  }

  int _displayRound(Mantra mantra) {
    if (!mantra.usesRounds) return 0;
    if (mantra.currentCount > 0 && mantra.beadsInCurrentRound == 0) {
      return mantra.completedRounds.clamp(1, mantra.totalRounds);
    }
    return (mantra.completedRounds + 1).clamp(1, mantra.totalRounds);
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) return '${duration.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mantra = _mantraOf(context);
    final isCompleted = mantra.isCompleted;
    final useSwipe =
        context.watch<ThemeProvider>().counterGesture == CounterGesture.swipe;

    // The loop follows the thumb up to just short of the next bead, so the
    // pull always feels like it is about to land.
    final pullFraction = (_dragOffset / _swipeThreshold).clamp(-0.85, 0.85);
    final ringProgress = mantra.currentCount + pullFraction;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: isCompleted
                  ? '${mantra.name} complete'
                  : 'Mala counter, ${mantra.currentCount} of '
                        '${mantra.targetCount}',
              value: '${mantra.currentCount}',
              increasedValue: '${mantra.currentCount + 1}',
              decreasedValue: '${mantra.currentCount - 1}',
              onIncrease: isCompleted ? null : _countBead,
              onDecrease: mantra.currentCount > 0 ? _undoBead : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Swiping counts, so tap is free to bring back the controls.
                onTap: useSwipe || isCompleted ? _toggleChrome : _countBead,
                // The way back to the controls in tap mode, where tap is
                // already spoken for.
                onLongPress: _toggleChrome,
                onVerticalDragStart: useSwipe && !isCompleted
                    ? _onDragStart
                    : null,
                onVerticalDragUpdate: useSwipe && !isCompleted
                    ? _onDragUpdate
                    : null,
                onVerticalDragEnd: useSwipe && !isCompleted
                    ? (_) => _onDragEnd()
                    : null,
                onVerticalDragCancel: useSwipe ? _onDragEnd : null,
                child: _buildStage(context, mantra, ringProgress, useSwipe),
              ),
            ),
          ),
          if (_showCoach) SwipeCoach(onDismiss: _dismissCoach),
          _buildRevealHandle(context),
          _buildTopChrome(context, mantra),
          _buildBottomChrome(context, mantra),
        ],
      ),
    );
  }

  Widget _buildStage(
    BuildContext context,
    Mantra mantra,
    double ringProgress,
    bool useSwipe,
  ) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    // Isolated so a drag repaints the beads and nothing else.
                    Positioned.fill(
                      child: Hero(
                        // Grows out of the little progress circle on the
                        // mantra card.
                        tag: 'mala-${mantra.id}',
                        flightShuttleBuilder: (_, animation, __, ___, ____) =>
                            FadeTransition(
                              opacity: animation,
                              child: MalaRing(
                                progress: ringProgress,
                                roundProgress: mantra.roundProgress,
                                beadsPerRound: mantra.beadsPerRound ?? 0,
                                isCompleted: mantra.isCompleted,
                              ),
                            ),
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _popController,
                            builder: (context, child) {
                              return MalaRing(
                                progress: ringProgress,
                                roundProgress: mantra.roundProgress,
                                beadsPerRound: mantra.beadsPerRound ?? 0,
                                pop: _popController.value,
                                isCompleted: mantra.isCompleted,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Inside the loop, so beads can never cross the text.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(58),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _popController,
                            child: _buildReadout(context, mantra),
                            builder: (context, child) {
                              // A brief swell as the bead lands, peaking
                              // mid-pulse and settling back.
                              final swell = math.sin(
                                math.pi * _popController.value,
                              );
                              return Transform.scale(
                                scale: 1 + 0.05 * swell,
                                child: child,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          _buildHint(context, mantra, useSwipe),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReadout(BuildContext context, Mantra mantra) {
    final scheme = Theme.of(context).colorScheme;
    final isCompleted = mantra.isCompleted;
    final accent = isCompleted ? const Color(0xFF43A047) : scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scales down rather than wrapping, so a five-digit count still fits.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${_headlineCount(mantra)}',
            maxLines: 1,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            mantra.usesRounds
                ? 'of ${mantra.beadsPerRound}'
                : 'of ${mantra.targetCount}',
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        if (mantra.usesRounds) ...[
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Mala ${_displayRound(mantra)} of ${mantra.totalRounds}',
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.tertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        if (_timerEndsAt != null) ...[
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatDuration(_timerRemaining),
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHint(BuildContext context, Mantra mantra, bool useSwipe) {
    final String text;
    if (mantra.isCompleted) {
      text = 'Complete';
    } else if (_isPaused) {
      text = 'Paused';
    } else if (useSwipe) {
      text = 'Pull down for the next bead';
    } else {
      text = 'Tap to count';
    }

    return AnimatedOpacity(
      opacity: _showChrome ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  /// Deliberately near-invisible: enough to find when looked for, not enough
  /// to pull the eye off the beads.
  Widget _buildRevealHandle(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: _showChrome ? 0 : 0.25,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: _showChrome,
            child: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _toggleChrome,
              tooltip: 'Show controls',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopChrome(BuildContext context, Mantra mantra) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedSlide(
          offset: _showChrome ? Offset.zero : const Offset(0, -0.4),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _showChrome ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showChrome,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Text(
                        mantra.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _timerEndsAt == null
                            ? Icons.timer_outlined
                            : Icons.timer,
                      ),
                      onPressed: _chooseTimer,
                      tooltip: 'Timed practice',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _confirmReset,
                      tooltip: 'Reset counter',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomChrome(BuildContext context, Mantra mantra) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedSlide(
          offset: _showChrome ? Offset.zero : const Offset(0, 0.4),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _showChrome ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showChrome,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${mantra.currentCount} of ${mantra.targetCount} total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: mantra.currentCount > 0
                              ? () {
                                  _undoBead();
                                  _keepChromeAlive();
                                }
                              : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: mantra.isCompleted ? null : _togglePause,
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                          label: Text(_isPaused ? 'Resume' : 'Pause'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
