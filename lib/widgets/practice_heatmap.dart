import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A year of practice as a grid of days, one column per week.
/// Shaded by minutes practised, which is the one measure japa, breathing and
/// meditation share.
///
/// Hand-rolled rather than pulling in a charting package: the shape is simple
/// and a dependency would be far larger than the widget.
class PracticeHeatmap extends StatelessWidget {
  final Map<DateTime, int> minutesByDay;
  final int weeks;

  const PracticeHeatmap({
    super.key,
    required this.minutesByDay,
    this.weeks = 27,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start on the Sunday of the week containing the first shown day, so
    // every column is a complete week and rows line up with weekdays.
    final firstDay = DateTime(
      today.year,
      today.month,
      today.day - (weeks * 7 - 1),
    );
    final start = DateTime(
      firstDay.year,
      firstDay.month,
      firstDay.day - (firstDay.weekday % 7),
    );

    final maximum = minutesByDay.values.isEmpty
        ? 0
        : minutesByDay.values.reduce((a, b) => a > b ? a : b);

    final columns = <Widget>[];
    for (var week = 0; week < weeks; week++) {
      final cells = <Widget>[];
      for (var weekday = 0; weekday < 7; weekday++) {
        final day = DateTime(
          start.year,
          start.month,
          start.day + week * 7 + weekday,
        );
        final isFuture = day.isAfter(today);
        final minutes = minutesByDay[day] ?? 0;

        cells.add(
          Padding(
            padding: const EdgeInsets.all(1.5),
            child: Tooltip(
              message: isFuture
                  ? ''
                  : '${DateFormat('MMM d, y').format(day)}: $minutes min',
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFuture
                      ? Colors.transparent
                      : _colorFor(context, minutes, maximum),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }
      columns.add(Column(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // Open on the most recent weeks
          child: Row(mainAxisSize: MainAxisSize.min, children: columns),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 4),
            for (final level in [0.0, 0.25, 0.5, 0.75, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _shade(context, level),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text('More', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Color _colorFor(BuildContext context, int minutes, int maximum) {
    if (minutes <= 0 || maximum <= 0) return _shade(context, 0);
    // Square root keeps a single heavy day from flattening everything else.
    final intensity = (minutes / maximum);
    return _shade(context, 0.15 + 0.85 * _sqrt(intensity));
  }

  static double _sqrt(double value) {
    if (value <= 0) return 0;
    var guess = value;
    for (var i = 0; i < 12; i++) {
      guess = 0.5 * (guess + value / guess);
    }
    return guess;
  }

  Color _shade(BuildContext context, double level) {
    final scheme = Theme.of(context).colorScheme;
    if (level <= 0) return scheme.surfaceContainerHighest;
    return Color.lerp(
      scheme.primary.withValues(alpha: 0.15),
      scheme.primary,
      level.clamp(0.0, 1.0),
    )!;
  }
}
