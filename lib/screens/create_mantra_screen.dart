import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mantra.dart';
import '../models/mantra_presets.dart';
import '../providers/mantra_provider.dart';

class CreateMantraScreen extends StatefulWidget {
  /// When supplied, the screen edits that mantra instead of creating one.
  final Mantra? mantra;

  const CreateMantraScreen({super.key, this.mantra});

  @override
  State<CreateMantraScreen> createState() => _CreateMantraScreenState();
}

class _CreateMantraScreenState extends State<CreateMantraScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetCountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _roundsController;
  late bool _isDaily;

  /// Japa is traditionally counted in malas; flat counting stays available for
  /// anyone who wants a plain number.
  late bool _useRounds;
  late int _beadsPerRound;

  static const List<int> _beadOptions = [108, 54, 27];

  bool get _isEditing => widget.mantra != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.mantra;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _targetCountController = TextEditingController(
      text: existing != null ? '${existing.targetCount}' : '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _isDaily = existing?.isDaily ?? false;

    _useRounds = existing?.usesRounds ?? true;
    _beadsPerRound = existing?.beadsPerRound ?? 108;
    _roundsController = TextEditingController(
      text: existing != null && existing.usesRounds
          ? '${existing.totalRounds}'
          : '1',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetCountController.dispose();
    _descriptionController.dispose();
    _roundsController.dispose();
    super.dispose();
  }

  void _applyPreset(MantraPreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _targetCountController.text = '${preset.targetCount}';
      _descriptionController.text = preset.description;
      _isDaily = true;
      _useRounds = true;
      _beadsPerRound = preset.beadsPerRound;
      _roundsController.text = '${preset.rounds}';
    });
  }

  /// In rounds mode the target is derived, so the two inputs can't disagree.
  int? get _resolvedTarget {
    if (!_useRounds) return int.tryParse(_targetCountController.text);
    final rounds = int.tryParse(_roundsController.text);
    if (rounds == null || rounds <= 0) return null;
    return rounds * _beadsPerRound;
  }

  void _saveMantra() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final targetCount = _resolvedTarget!;
    final description = _descriptionController.text.trim();
    final provider = context.read<MantraProvider>();
    final existing = widget.mantra;

    if (existing != null) {
      provider.updateMantra(
        existing.copyWith(
          name: name,
          targetCount: targetCount,
          description: description.isEmpty ? null : description,
          clearDescription: description.isEmpty,
          isDaily: _isDaily,
          beadsPerRound: _useRounds ? _beadsPerRound : null,
          clearBeadsPerRound: !_useRounds,
          // Becoming daily starts today's cycle; ceasing to be daily has no
          // cycle left to track.
          lastResetDate: _isDaily && !existing.isDaily ? DateTime.now() : null,
          clearLastResetDate: !_isDaily,
        ),
      );
    } else {
      provider.addMantra(
        Mantra.create(
          name: name,
          targetCount: targetCount,
          description: description.isEmpty ? null : description,
          isDaily: _isDaily,
          beadsPerRound: _useRounds ? _beadsPerRound : null,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Mantra' : 'Create Mantra'),
        actions: [
          TextButton(onPressed: _saveMantra, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing) ...[
              Text(
                'Start from a common mantra',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MantraPreset.all.map((preset) {
                  return ActionChip(
                    label: Text(preset.name),
                    onPressed: () => _applyPreset(preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Mantra Name',
                hintText: 'e.g., Om, Gayatri, or custom mantra',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a mantra name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              // The preview below reads these controllers, so it needs a
              // rebuild as the user types.
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Count in malas or as a flat number.
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Count in malas'),
                    subtitle: const Text(
                      'Traditional japa is counted in rounds of 108 beads',
                    ),
                    value: _useRounds,
                    onChanged: (value) => setState(() => _useRounds = value),
                    secondary: const Icon(Icons.blur_circular),
                  ),
                  if (_useRounds)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _roundsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Malas',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final rounds = int.tryParse(value ?? '');
                                    if (rounds == null || rounds <= 0) {
                                      return 'Enter a number';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _beadsPerRound,
                                  decoration: const InputDecoration(
                                    labelText: 'Beads per mala',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _beadOptions
                                      .map(
                                        (beads) => DropdownMenuItem(
                                          value: beads,
                                          child: Text('$beads'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _beadsPerRound = value ?? 108,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _resolvedTarget == null
                                ? 'Enter how many malas to complete'
                                : 'Total: $_resolvedTarget repetitions',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (!_useRounds)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextFormField(
                        controller: _targetCountController,
                        decoration: const InputDecoration(
                          labelText: 'Target Count',
                          hintText: 'e.g., 108, 1000, or any number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_useRounds) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a target count';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Additional notes or meaning',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Daily Mantra'),
                subtitle: const Text(
                  'Resets automatically at 4 AM each morning',
                ),
                value: _isDaily,
                onChanged: (value) {
                  setState(() {
                    _isDaily = value;
                  });
                },
                secondary: Icon(
                  _isDaily ? Icons.wb_sunny : Icons.repeat,
                  color: _isDaily
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Mantra Name'
                          : _nameController.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_resolvedTarget != null)
                      Text(
                        _useRounds
                            ? '${_roundsController.text} × $_beadsPerRound = '
                                  '$_resolvedTarget repetitions'
                            : 'Target: $_resolvedTarget repetitions',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (_descriptionController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _descriptionController.text,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
