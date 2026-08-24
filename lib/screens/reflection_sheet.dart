import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';

/// A short prompt offered after a round is finished, saved into the gratitude
/// journal and tagged with the mantra just practised.
class ReflectionSheet extends StatefulWidget {
  final String mantraName;

  const ReflectionSheet({super.key, required this.mantraName});

  @override
  State<ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<ReflectionSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  /// Openers, for when sitting down to a blank box is the obstacle.
  static const List<String> _prompts = [
    'What came up during this round?',
    'What am I grateful for right now?',
    'How does my mind feel compared to when I started?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final box = await Hive.openBox<JournalEntry>('journal_entries');
      final entry = JournalEntry.create(
        date: DateTime.now(),
        content: text,
        mantraName: widget.mantraName,
      );
      await box.put(entry.id, entry);

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Saved to your journal ✨')),
      );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'After ${widget.mantraName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'A line or two, while it is still fresh.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _prompts.first,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _prompts
                .map(
                  (prompt) => ActionChip(
                    label: Text(
                      prompt,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onPressed: () => setState(() {
                      _controller.text = '$prompt\n\n';
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Not now'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving || _controller.text.trim().isEmpty
                    ? null
                    : _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
