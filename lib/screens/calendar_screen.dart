import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/mantra_provider.dart';
import '../models/daily_completion.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Calendar'),
      ),
      body: Consumer<MantraProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now(), // Disable future dates
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  disabledTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(),
              Expanded(
                child: _selectedDay != null
                    ? _buildDayDetails(context, provider, _selectedDay!)
                    : Center(
                        child: Text(
                          'Select a day to see details',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  Widget _buildDayDetails(BuildContext context, MantraProvider provider, DateTime selectedDay) {
    final dailyMantras = provider.mantras.where((mantra) => mantra.isDaily).toList();
    final dayStart = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int completedCount = 0;
    int totalCount = dailyMantras.length;

    for (final mantra in dailyMantras) {
      // For now, we'll consider a mantra completed if it was completed on that day
      // In a full implementation, we'd track completion timestamps
      if (mantra.isCompleted) {
        completedCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Practice - ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayStat('Completed', '$completedCount/$totalCount', Icons.check_circle,
                      completedCount == totalCount ? Colors.green : Colors.orange),
                  _buildDayStat('Missed', '${totalCount - completedCount}', Icons.cancel,
                      totalCount - completedCount > 0 ? Colors.red : Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Daily Mantras',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: dailyMantras.isEmpty
                ? Center(
                    child: Text(
                      'No daily mantras set up yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: dailyMantras.length,
                    itemBuilder: (context, index) {
                      final mantra = dailyMantras[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            mantra.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: mantra.isCompleted ? Colors.green : Colors.grey,
                          ),
                          title: Text(mantra.name),
                          subtitle: Text('${mantra.currentCount} / ${mantra.targetCount}'),
                          trailing: CircularProgressIndicator(
                            value: mantra.progress,
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
