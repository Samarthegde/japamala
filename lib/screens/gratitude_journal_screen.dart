import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/haptic_feedback.dart';

class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen> {
  Box<JournalEntry>? _journalBox;
  final TextEditingController _entryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initJournalBox();
  }

  Future<void> _initJournalBox() async {
    _journalBox = await Hive.openBox<JournalEntry>('journal_entries');
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  List<JournalEntry> _getEntriesForDate(DateTime date) {
    if (_journalBox == null) return [];
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _journalBox!.values
        .where((entry) => entry.dateKey == dateKey)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  Future<void> _addJournalEntry() async {
    if (_journalBox == null || _entryController.text.trim().isEmpty) return;

    final entry = JournalEntry.create(
      date: _selectedDate,
      content: _entryController.text.trim(),
    );

    await _journalBox!.put(entry.id, entry);
    _entryController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gratitude noted ✨')),
      );
    }

    setState(() {});
  }

  Future<void> _deleteEntry(String entryId) async {
    if (_journalBox == null) return;
    await _journalBox!.delete(entryId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gratitude Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                      ? () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),

          // Quick entry section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What are you grateful for today?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _entryController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'I am grateful for...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addJournalEntry,
                      ),
                    ),
                    onSubmitted: (_) => _addJournalEntry(),
                  ),
                ],
              ),
            ),
          ),

          // Entries list
          Expanded(
            child: _getEntriesForDate(_selectedDate).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries for this day',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first gratitude note above',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _getEntriesForDate(_selectedDate).length,
                    itemBuilder: (context, index) {
                      final entry = _getEntriesForDate(_selectedDate)[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('h:mm a').format(entry.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteEntry(entry.id),
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (entry.mantraName != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'After ${entry.mantraName} practice',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
}
