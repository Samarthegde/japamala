import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/animations.dart';
import '../widgets/practice_heatmap.dart';

/// Turns the session log into something readable, across every kind of
/// practice rather than japa alone.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  /// Null shows everything.
  SessionKind? _kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: Consumer2<SessionProvider, MantraProvider>(
        builder: (context, sessionProvider, mantraProvider, child) {
          final all = sessionProvider.sessions;
          if (all.isEmpty) return _buildEmptyState(context);

          final sessions = _kind == null
              ? all
              : all.where((session) => session.kind == _kind).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildKindFilter(context, all),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                _buildCard(
                  context,
                  'Nothing yet',
                  Text(
                    'No ${_kind!.label.toLowerCase()} practice recorded so far.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else ...[
                _buildSummary(context, sessionProvider, sessions),
                const SizedBox(height: 16),
                _buildCard(
                  context,
                  'Minutes practised · last 30 days',
                  PracticeBarChart(data: _minutesPerDay(sessions, 30)),
                  order: 1,
                ),
                const SizedBox(height: 16),
                _buildCard(
                  context,
                  'This year',
                  PracticeHeatmap(minutesByDay: _minutesByDay(sessions)),
                  order: 2,
                ),
                const SizedBox(height: 16),
                _buildCard(
                  context,
                  'When you practise',
                  _TimeOfDayBreakdown(sessions: sessions),
                  order: 3,
                ),
                const SizedBox(height: 16),
                _buildCard(
                  context,
                  'By practice',
                  _ActivityBreakdown(
                    sessions: sessions,
                    mantraProvider: mantraProvider,
                  ),
                  order: 4,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildKindFilter(BuildContext context, List<Session> all) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _kind == null,
              onSelected: (_) => setState(() => _kind = null),
            ),
          ),
          for (final kind in SessionKind.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(kind.label),
                selected: _kind == kind,
                onSelected: (_) => setState(() => _kind = kind),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights,
              size: 72,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing to show yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Count a round, breathe, or sit for a while and your practice '
              'will start showing up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    Widget child, {
    int order = 0,
  }) {
    return FadeSlideIn(
      delay: FadeSlideIn.stagger(order, step: 70),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    SessionProvider provider,
    List<Session> sessions,
  ) {
    final totalTime = sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );
    final averageSession = Duration(
      seconds: (totalTime.inSeconds / sessions.length).round(),
    );

    final japa = sessions.where((s) => s.kind == SessionKind.japa).toList();
    final beads = japa.fold<int>(0, (sum, s) => sum + s.count);
    final cycles = sessions
        .where((s) => s.kind == SessionKind.breathing)
        .fold<int>(0, (sum, s) => sum + s.count);

    // Only sittings long enough to be meaningful inform the pace figure.
    final timedJapa = japa.where((s) => s.duration.inSeconds >= 10).toList();
    final beadsPerMinute = timedJapa.isEmpty
        ? 0.0
        : timedJapa.fold<int>(0, (sum, s) => sum + s.count) /
              (timedJapa.fold<int>(0, (sum, s) => sum + s.duration.inSeconds) /
                  60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _summaryStat(
              context,
              'Current streak',
              '${provider.currentStreak}d',
            ),
            _summaryStat(context, 'Best streak', '${provider.longestStreak}d'),
            _summaryStat(context, 'Sittings', '${sessions.length}'),
            _summaryStat(context, 'Time practised', _formatDuration(totalTime)),
            _summaryStat(
              context,
              'Average sitting',
              _formatDuration(averageSession),
            ),
            if (beads > 0)
              _summaryStat(
                context,
                'Beads',
                NumberFormat.decimalPattern().format(beads),
              ),
            if (cycles > 0)
              _summaryStat(
                context,
                'Breath cycles',
                NumberFormat.decimalPattern().format(cycles),
              ),
            if (beadsPerMinute > 0)
              _summaryStat(
                context,
                'Pace',
                '${beadsPerMinute.toStringAsFixed(0)}/min',
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }

  /// Minutes is the one measure every kind of practice shares — beads mean
  /// nothing for a silent sitting.
  static Map<DateTime, int> _minutesByDay(List<Session> sessions) {
    final byDay = <DateTime, int>{};
    for (final session in sessions) {
      final day = MantraProvider.practiceDayOf(session.endTime);
      byDay[day] = (byDay[day] ?? 0) + session.duration.inMinutes;
    }
    return byDay;
  }

  static List<({DateTime day, int value})> _minutesPerDay(
    List<Session> sessions,
    int days,
  ) {
    final byDay = _minutesByDay(sessions);
    final today = MantraProvider.practiceDayOf(DateTime.now());

    return [
      for (var i = days - 1; i >= 0; i--)
        (
          day: DateTime(today.year, today.month, today.day - i),
          value: byDay[DateTime(today.year, today.month, today.day - i)] ?? 0,
        ),
    ];
  }
}

/// A plain bar chart. Deliberately hand-rolled rather than pulling in a
/// charting dependency for one view.
class PracticeBarChart extends StatelessWidget {
  final List<({DateTime day, int value})> data;

  const PracticeBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maximum = data.fold<int>(
      0,
      (max, e) => e.value > max ? e.value : max,
    );
    if (maximum == 0) {
      return Text(
        'No practice recorded in this period.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((entry) {
              final fraction = entry.value / maximum;
              return Expanded(
                child: Tooltip(
                  message:
                      '${DateFormat('MMM d').format(entry.day)}: '
                      '${entry.value} min',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (fraction * 110).clamp(
                            entry.value > 0 ? 2 : 0,
                            110,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM d').format(data.first.day),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'peak $maximum min',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              DateFormat('MMM d').format(data.last.day),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeOfDayBreakdown extends StatelessWidget {
  final List<Session> sessions;

  const _TimeOfDayBreakdown({required this.sessions});

  static const List<({String label, int from, int to})> _bands = [
    (label: 'Early morning', from: 4, to: 8),
    (label: 'Morning', from: 8, to: 12),
    (label: 'Afternoon', from: 12, to: 17),
    (label: 'Evening', from: 17, to: 21),
    (label: 'Night', from: 21, to: 28), // wraps past midnight to 4am
  ];

  @override
  Widget build(BuildContext context) {
    final minutes = <String, int>{for (final band in _bands) band.label: 0};
    for (final session in sessions) {
      // Shift pre-dawn hours into the previous evening's band.
      final hour = session.startTime.hour < 4
          ? session.startTime.hour + 24
          : session.startTime.hour;
      for (final band in _bands) {
        if (hour >= band.from && hour < band.to) {
          minutes[band.label] =
              minutes[band.label]! + session.duration.inMinutes;
          break;
        }
      }
    }

    final total = minutes.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return const Text('Not enough practice yet.');

    return Column(
      children: _bands.map((band) {
        final value = minutes[band.label]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  band.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / total,
                    minHeight: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  '${(value / total * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Groups by mantra for japa, and by pattern for everything else.
class _ActivityBreakdown extends StatelessWidget {
  final List<Session> sessions;
  final MantraProvider mantraProvider;

  const _ActivityBreakdown({
    required this.sessions,
    required this.mantraProvider,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = <String, int>{};
    for (final session in sessions) {
      final name = session.kind == SessionKind.japa
          ? (mantraProvider.getMantraById(session.mantraId)?.name ??
                'Deleted mantra')
          : (session.title ?? session.kind.label);
      minutes[name] = (minutes[name] ?? 0) + session.duration.inMinutes;
    }

    final entries = minutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = minutes.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return const Text('Not enough practice yet.');

    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${entry.value} min  (${(entry.value / total * 100).round()}%)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
