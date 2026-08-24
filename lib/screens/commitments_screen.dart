import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/commitment.dart';
import '../models/mantra.dart';
import '../providers/commitment_provider.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/animations.dart';

/// Sankalpa — long-term vows, e.g. 125,000 repetitions over several months.
class CommitmentsScreen extends StatelessWidget {
  const CommitmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sankalpa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New vow'),
      ),
      body: Consumer3<CommitmentProvider, MantraProvider, SessionProvider>(
        builder: (context, commitments, mantras, sessions, child) {
          if (commitments.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (commitments.commitments.isEmpty) {
            return _buildEmptyState(context);
          }

          final active = commitments.active;
          final done = commitments.completed;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              if (active.isNotEmpty) ...[
                Text(
                  'In progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final (index, commitment) in active.indexed)
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(index),
                    child: _CommitmentCard(
                      progress: commitments.progressFor(
                        commitment,
                        sessions.sessions,
                      ),
                      mantra: mantras.getMantraById(commitment.mantraId),
                    ),
                  ),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Fulfilled',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final commitment in done)
                  _CommitmentCard(
                    progress: commitments.progressFor(
                      commitment,
                      sessions.sessions,
                    ),
                    mantra: mantras.getMantraById(commitment.mantraId),
                  ),
              ],
            ],
          );
        },
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
              Icons.flag,
              size: 72,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No vows yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'A sankalpa is a resolve to complete a set number of '
              'repetitions — often over weeks or months. Your practice counts '
              'toward it automatically.',
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

  static void _showCreateSheet(BuildContext context) {
    final mantras = context.read<MantraProvider>().mantras;
    if (mantras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a mantra first.')));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CreateCommitmentSheet(mantras: mantras),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final CommitmentProgress progress;
  final Mantra? mantra;

  const _CommitmentCard({required this.progress, this.mantra});

  @override
  Widget build(BuildContext context) {
    final commitment = progress.commitment;
    final ahead = progress.beadsAheadOfSchedule;
    final finish = progress.projectedFinishDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mantra?.name ?? 'Unknown mantra',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (commitment.isComplete)
                  const Icon(Icons.verified, color: Colors.green),
                PopupMenuButton<String>(
                  tooltip: 'Vow options',
                  onSelected: (value) {
                    if (value == 'delete') {
                      context.read<CommitmentProvider>().delete(commitment.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (commitment.intention != null &&
                commitment.intention!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '"${commitment.intention}"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 10,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat.decimalPattern().format(progress.completedCount)}'
              ' of '
              '${NumberFormat.decimalPattern().format(commitment.targetCount)}'
              '  ·  ${(progress.fraction * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _stat(
                  context,
                  'Pace',
                  '${progress.pacePerDay.toStringAsFixed(0)}/day',
                ),
                if (!commitment.isComplete && finish != null)
                  _stat(
                    context,
                    'At this pace',
                    DateFormat('MMM d, y').format(finish),
                  ),
                if (commitment.deadline != null)
                  _stat(
                    context,
                    'By',
                    DateFormat('MMM d, y').format(commitment.deadline!),
                  ),
                if (!commitment.isComplete && ahead != null)
                  _stat(
                    context,
                    ahead >= 0 ? 'Ahead' : 'Behind',
                    NumberFormat.decimalPattern().format(ahead.abs()),
                    color: ahead >= 0 ? Colors.green : Colors.deepOrange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CreateCommitmentSheet extends StatefulWidget {
  final List<Mantra> mantras;

  const _CreateCommitmentSheet({required this.mantras});

  @override
  State<_CreateCommitmentSheet> createState() => _CreateCommitmentSheetState();
}

class _CreateCommitmentSheetState extends State<_CreateCommitmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController(text: '125000');
  final _intentionController = TextEditingController();
  late String _mantraId = widget.mantras.first.id;
  DateTime? _deadline;

  /// Traditional purascharana counts, offered as shortcuts.
  static const List<int> _suggestedTargets = [1080, 10800, 125000, 1000000];

  @override
  void dispose() {
    _targetController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CommitmentProvider>().add(
      Commitment.create(
        mantraId: _mantraId,
        targetCount: int.parse(_targetController.text),
        deadline: _deadline,
        intention: _intentionController.text.trim().isEmpty
            ? null
            : _intentionController.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New sankalpa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _mantraId,
              decoration: const InputDecoration(
                labelText: 'Mantra',
                border: OutlineInputBorder(),
              ),
              items: widget.mantras
                  .map(
                    (mantra) => DropdownMenuItem(
                      value: mantra.id,
                      child: Text(mantra.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _mantraId = value ?? _mantraId),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Total repetitions',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final count = int.tryParse(value ?? '');
                if (count == null || count <= 0) return 'Enter a number';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _suggestedTargets.map((target) {
                return ActionChip(
                  label: Text(NumberFormat.decimalPattern().format(target)),
                  onPressed: () =>
                      setState(() => _targetController.text = '$target'),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _intentionController,
              decoration: const InputDecoration(
                labelText: 'Intention (optional)',
                hintText: 'What is this practice dedicated to?',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _deadline == null
                    ? 'No deadline'
                    : 'Finish by ${DateFormat('MMM d, y').format(_deadline!)}',
              ),
              trailing: _deadline == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    ),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? now.add(const Duration(days: 90)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365 * 10)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Take the vow'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
