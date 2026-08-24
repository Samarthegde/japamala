import 'package:flutter/material.dart';

/// A one-time hint showing how the mala is counted.
///
/// The pull gesture has no affordance of its own — someone opening the app for
/// the first time will tap the ring and nothing will happen. A ghosted thumb
/// tracing the motion is the shortest way to say "pull this".
class SwipeCoach extends StatefulWidget {
  final VoidCallback onDismiss;

  const SwipeCoach({super.key, required this.onDismiss});

  @override
  State<SwipeCoach> createState() => _SwipeCoachState();
}

class _SwipeCoachState extends State<SwipeCoach>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _travel;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();

    // Travels down, then rests before repeating — a pull, not a drift.
    _travel = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.55, curve: Curves.easeInOut),
    );
    // Fades in as the pull starts and out as it lands.
    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      // The scrim and the button are siblings on purpose: an IgnorePointer
      // blocks hit testing for its whole subtree, so a button nested inside
      // one can never be pressed.
      child: Stack(
        children: [
          IgnorePointer(
            // Never blocks the very gesture it is teaching — a first pull
            // dismisses this and counts.
            child: Container(
              color: scheme.surface.withValues(alpha: 0.82),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pull to count',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Drag down anywhere to bring the next bead to your '
                        'thumb, as you would on a real mala. Pull up to give '
                        'one back.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(height: 150, child: _buildThumb(context)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: Center(
              child: TextButton(
                onPressed: widget.onDismiss,
                child: const Text('Got it'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // The path the thumb takes.
            Positioned(
              top: 12,
              child: Container(
                width: 2,
                height: 108,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              top: 8 + _travel.value * 100,
              child: Opacity(
                opacity: _fade.value,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.18),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.touch_app, color: scheme.primary, size: 22),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
