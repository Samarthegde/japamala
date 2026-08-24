import 'package:flutter/material.dart';

/// Entrance animation: fades and lifts a widget into place.
///
/// Uses a controller rather than [TweenAnimationBuilder] because a stagger
/// needs a delayed start, which the implicit builders can't express.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  /// How far below its resting place the child begins, in logical pixels.
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    this.delay = Duration.zero,
    this.offset = 16,
  });

  /// Staggered delay for item [index] in a list, capped so the tail of a long
  /// list doesn't keep the user waiting.
  static Duration stagger(int index, {int step = 45, int max = 400}) =>
      Duration(milliseconds: (index * step).clamp(0, max));

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        // The list may have scrolled this item away before its turn came.
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      // The subtree is built once and reused every frame.
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offset),
            child: child,
          ),
        );
      },
    );
  }
}

/// A number that counts up to its new value instead of snapping.
///
/// [TweenAnimationBuilder] animates from wherever it currently is when the end
/// changes, which is exactly the behaviour a running total wants.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return Text('${animated.round()}', style: style);
      },
    );
  }
}

/// A bar that grows from nothing, for the insights chart.
class GrowBar extends StatelessWidget {
  final double fraction;
  final double maxHeight;
  final Color color;
  final Duration delay;

  const GrowBar({
    super.key,
    required this.fraction,
    required this.maxHeight,
    required this.color,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          height: (value * maxHeight).clamp(fraction > 0 ? 2 : 0, maxHeight),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        );
      },
    );
  }
}

/// Screen transition used throughout the app: a soft fade with a slight rise,
/// rather than the platform default, so navigation feels of a piece with the
/// rest of the motion.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
