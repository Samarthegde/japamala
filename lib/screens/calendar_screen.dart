import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/mantra.dart';
import '../models/session.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = MantraProvider.practiceDayOf(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Calendar')),
      body: Consumer2<MantraProvider, SessionProvider>(
        builder: (context, provider, sessions, child) {
          return Column(
            children: [
              _buildStreakCard(context, sessions),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now(), // Disable future dates
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                // A marker on every day with practice of any kind, matching
                // what the streak counts.
                eventLoader: (day) =>
                    sessions.practisedOn(day) ? const ['practised'] : const [],
                onDaySelected: (selectedDay, focusedDay) {
                  // Only allow selecting past and present dates
                  if (selectedDay.isAfter(DateTime.now())) {
                    return;
                  }
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                enabledDayPredicate: (day) {
                  // Disable future dates
                  return !day.isAfter(DateTime.now());
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  disabledTextStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(),
              Expanded(
                child: _selectedDay != null
                    ? _buildDayDetails(
                        context,
                        provider,
                        sessions,
                        _selectedDay!,
                      )
                    : Center(
                        child: Text(
                          'Select a day to see details',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, SessionProvider provider) {
    final current = provider.currentStreak;
    final longest = provider.longestStreak;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStreakStat(
              context,
              Icons.local_fire_department,
              current,
              current == 1 ? 'Day' : 'Days',
              current > 0 ? Colors.deepOrange : Colors.grey,
            ),
            _buildStreakStat(
              context,
              Icons.emoji_events,
              longest,
              'Best streak',
              longest > 0 ? Colors.amber.shade700 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(
    BuildContext context,
    IconData icon,
    int value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildDayDetails(
    BuildContext context,
    MantraProvider provider,
    SessionProvider sessionProvider,
    DateTime selectedDay,
  ) {
    // Only the mantras that already existed on this day are expected of it.
    final dailyMantras = provider.dailyMantrasOn(selectedDay);
    final isToday = isSameDay(
      MantraProvider.practiceDayOf(DateTime.now()),
      selectedDay,
    );

    final completedCount = dailyMantras
        .where((mantra) => provider.isCompletedOn(mantra.id, selectedDay))
        .length;
    final totalCount = dailyMantras.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Practice - ${DateFormat('EEEE, MMMM d, y').format(selectedDay)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayStat(
                    'Completed',
                    '$completedCount/$totalCount',
                    Icons.check_circle,
                    totalCount > 0 && completedCount == totalCount
                        ? Colors.green
                        : Colors.orange,
                  ),
                  _buildDayStat(
                    'Missed',
                    '${totalCount - completedCount}',
                    Icons.cancel,
                    totalCount - completedCount > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPracticeSummary(context, sessionProvider, selectedDay),
          const SizedBox(height: 16),
          Text('Daily Mantras', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: dailyMantras.isEmpty
                ? Center(
                    child: Text(
                      provider.mantras.any((mantra) => mantra.isDaily)
                          ? 'No daily mantras existed on this day'
                          : 'No daily mantras set up yet',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: dailyMantras.length,
                    itemBuilder: (context, index) {
                      return _buildMantraRow(
                        context,
                        provider,
                        dailyMantras[index],
                        selectedDay,
                        isToday: isToday,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMantraRow(
    BuildContext context,
    MantraProvider provider,
    Mantra mantra,
    DateTime day, {
    required bool isToday,
  }) {
    final completion = provider.completionFor(mantra.id, day);
    final isCompleted = completion?.completed ?? false;

    // History records that a day was finished, not the running count, so only
    // today can show live progress.
    final String subtitle;
    if (isCompleted && completion?.completionTime != null) {
      subtitle =
          'Completed at ${DateFormat('h:mm a').format(completion!.completionTime!)}';
    } else if (isCompleted) {
      subtitle = 'Completed';
    } else if (isToday) {
      subtitle = '${mantra.currentCount} / ${mantra.targetCount} so far';
    } else {
      subtitle = 'Not completed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(mantra.name),
        subtitle: Text(subtitle),
        trailing: isToday && !isCompleted
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: mantra.progress,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDayStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  /// What was actually practised on the selected day — a daily mantra left
  /// unfinished doesn't mean nothing happened.
  Widget _buildPracticeSummary(
    BuildContext context,
    SessionProvider provider,
    DateTime day,
  ) {
    final target = MantraProvider.practiceDayOf(day);
    final sessions = provider.sessions
        .where(
          (session) => MantraProvider.practiceDayOf(session.endTime) == target,
        )
        .toList();

    if (sessions.isEmpty) {
      return Text(
        'No practice recorded on this day',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    final minutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.duration.inMinutes,
    );
    final byKind = <SessionKind, int>{};
    for (final session in sessions) {
      byKind[session.kind] = (byKind[session.kind] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${sessions.length} '
                  '${sessions.length == 1 ? 'sitting' : 'sittings'}'
                  '${minutes > 0 ? ' · $minutes min' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: byKind.entries
                  .map(
                    (entry) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${entry.key.label} ×${entry.value}'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
