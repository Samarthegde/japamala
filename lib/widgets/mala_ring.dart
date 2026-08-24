import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A mala drawn as what it actually is — a closed loop of beads — turning past
/// a fixed thumb position at the bottom of the ring.
///
/// Keeping the beads on the perimeter leaves the middle free for the count,
/// so nothing overlaps regardless of how large the numbers get.
class MalaRing extends StatelessWidget {
  /// Continuous bead position: the whole part is the bead at the thumb, the
  /// fraction is how far the current pull has travelled toward the next one.
  final double progress;

  /// Beads in one mala, used to place the sumeru. Zero disables it.
  final int beadsPerRound;

  /// How far through the current mala, for the outer arc.
  final double roundProgress;

  /// 0–1 pulse played each time a bead registers.
  final double pop;

  final bool isCompleted;

  /// Bead positions drawn around the loop. Not the real count — a full 108
  /// would be a smear at this size.
  static const int visibleBeads = 24;

  const MalaRing({
    super.key,
    required this.progress,
    required this.roundProgress,
    this.beadsPerRound = 0,
    this.pop = 0,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isCompleted ? const Color(0xFF43A047) : scheme.primary;

    return CustomPaint(
      painter: _MalaRingPainter(
        progress: progress,
        roundProgress: roundProgress,
        beadsPerRound: beadsPerRound,
        pop: pop,
        cordColor: scheme.onSurface.withValues(alpha: 0.10),
        beadColor: accent,
        sumeruColor: scheme.tertiary,
        arcColor: accent.withValues(alpha: 0.35),
        arcTrackColor: scheme.onSurface.withValues(alpha: 0.06),
        markerColor: accent.withValues(alpha: 0.55),
      ),
      size: Size.infinite,
    );
  }
}

class _MalaRingPainter extends CustomPainter {
  final double progress;
  final double roundProgress;
  final int beadsPerRound;
  final double pop;
  final Color cordColor;
  final Color beadColor;
  final Color sumeruColor;
  final Color arcColor;
  final Color arcTrackColor;
  final Color markerColor;

  _MalaRingPainter({
    required this.progress,
    required this.roundProgress,
    required this.beadsPerRound,
    required this.pop,
    required this.cordColor,
    required this.beadColor,
    required this.sumeruColor,
    required this.arcColor,
    required this.arcTrackColor,
    required this.markerColor,
  });

  /// The thumb sits at the bottom of the loop.
  static const double _markerAngle = math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30;
    if (radius <= 0) return;

    final anglePerBead = 2 * math.pi / MalaRing.visibleBeads;

    _paintCord(canvas, center, radius);
    _paintRoundArc(canvas, center, radius);
    _paintBeads(canvas, center, radius, anglePerBead);
    _paintMarker(canvas, center, radius);
  }

  void _paintCord(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = cordColor,
    );
  }

  /// A thin arc outside the beads showing how far through the mala you are.
  void _paintRoundArc(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius + 22);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = arcTrackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (roundProgress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start at the top, as progress rings do
      2 * math.pi * roundProgress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = arcColor,
    );
  }

  void _paintBeads(
    Canvas canvas,
    Offset center,
    double radius,
    double anglePerBead,
  ) {
    final base = progress.floor();
    final half = MalaRing.visibleBeads ~/ 2;

    for (var slot = -half; slot <= half; slot++) {
      final index = base + slot;
      if (index < 0) continue; // Nothing before the first bead

      // Pulling advances progress, which turns the loop past the thumb.
      final angle = _markerAngle + (progress - index) * anglePerBead;

      // How near the thumb this bead is, as 0–1.
      var delta = (angle - _markerAngle) % (2 * math.pi);
      if (delta > math.pi) delta -= 2 * math.pi;
      final closeness = (1 - delta.abs() / math.pi).clamp(0.0, 1.0);

      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;

      final isSumeru =
          beadsPerRound > 0 && index > 0 && index % beadsPerRound == 0;

      // Cubed so only the few beads by the thumb grow, keeping the loop calm.
      final emphasis = math.pow(closeness, 3).toDouble();
      final beadRadius = (isSumeru ? 7.0 : 5.0) + 9.0 * emphasis;
      final opacity = (0.20 + 0.80 * closeness).clamp(0.0, 1.0);
      final color = isSumeru ? sumeruColor : beadColor;

      // A soft halo behind the bead at the thumb.
      if (emphasis > 0.35) {
        canvas.drawCircle(
          position,
          beadRadius + 10 * emphasis,
          Paint()..color = color.withValues(alpha: 0.16 * emphasis),
        );
      }

      canvas.drawCircle(
        position,
        beadRadius,
        Paint()..color = color.withValues(alpha: opacity),
      );

      // The pulse rides on the bead that just registered.
      if (pop > 0 && emphasis > 0.9) {
        canvas.drawCircle(
          position,
          beadRadius + 26 * pop,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: 0.45 * (1 - pop)),
        );
      }
    }
  }

  /// A small notch outside the loop marking where the thumb rests.
  void _paintMarker(Canvas canvas, Offset center, double radius) {
    final tip = center + Offset(0, radius + 8);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 6, tip.dy + 9)
      ..lineTo(tip.dx + 6, tip.dy + 9)
      ..close();
    canvas.drawPath(path, Paint()..color = markerColor);
  }

  @override
  bool shouldRepaint(_MalaRingPainter old) =>
      old.progress != progress ||
      old.roundProgress != roundProgress ||
      old.pop != pop ||
      old.beadColor != beadColor ||
      old.beadsPerRound != beadsPerRound;
}
