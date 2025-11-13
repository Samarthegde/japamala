import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mantra.dart';
import '../providers/mantra_provider.dart';

class CreateMantraScreen extends StatefulWidget {
  const CreateMantraScreen({super.key});

  @override
  State<CreateMantraScreen> createState() => _CreateMantraScreenState();
}

class _CreateMantraScreenState extends State<CreateMantraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetCountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isDaily = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetCountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveMantra() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final targetCount = int.parse(_targetCountController.text);
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      final mantra = Mantra.create(
        name: name,
        targetCount: targetCount,
        description: description,
        isDaily: _isDaily,
      );

      context.read<MantraProvider>().addMantra(mantra);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Mantra'),
        actions: [
          TextButton(
            onPressed: _saveMantra,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetCountController,
              decoration: const InputDecoration(
                labelText: 'Target Count',
                hintText: 'e.g., 108, 1000, or any number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a target count';
                }
                final count = int.tryParse(value);
                if (count == null || count <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
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
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Daily Mantra'),
                subtitle: const Text('Resets automatically at 4 AM each morning'),
                value: _isDaily,
                onChanged: (value) {
                  setState(() {
                    _isDaily = value;
                  });
                },
                secondary: Icon(
                  _isDaily ? Icons.wb_sunny : Icons.repeat,
                  color: _isDaily ? Colors.orange : Theme.of(context).colorScheme.primary,
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
                      _nameController.text.isEmpty ? 'Mantra Name' : _nameController.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_targetCountController.text.isNotEmpty)
                      Text(
                        'Target: ${_targetCountController.text} repetitions',
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
