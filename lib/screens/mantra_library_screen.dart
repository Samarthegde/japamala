import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/mantra_presets.dart';
import '../providers/mantra_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback.dart';

/// Reference for the mantras the app ships with: script, pronunciation and
/// sense, plus a one-tap way to start counting one.
class MantraLibraryScreen extends StatelessWidget {
  const MantraLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mantra Library')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MantraPreset.all.length,
        itemBuilder: (context, index) {
          return _MantraEntry(preset: MantraPreset.all[index]);
        },
      ),
    );
  }
}

class _MantraEntry extends StatelessWidget {
  final MantraPreset preset;

  const _MantraEntry({required this.preset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(preset.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          preset.transliteration.split('\n').first,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Devanagari needs generous line height to render its matras
          // without clipping.
          SelectableText(
            preset.devanagari,
            style: theme.textTheme.titleLarge?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 12),
          SelectableText(
            preset.transliteration,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text('Meaning', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(preset.meaning, style: theme.textTheme.bodyMedium),
          if (preset.source != null) ...[
            const SizedBox(height: 12),
            Text('Source', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(preset.source!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '${preset.devanagari}\n\n'
                          '${preset.transliteration}\n\n'
                          '${preset.meaning}',
                    ),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Copied')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  final provider = context.read<MantraProvider>();
                  if (context.read<ThemeProvider>().hapticEnabled) {
                    HapticFeedbackService.buttonPress();
                  }

                  final existing = provider.mantras.where(
                    (mantra) => mantra.name == preset.name,
                  );
                  if (existing.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${preset.name} is already in your list'),
                      ),
                    );
                    return;
                  }

                  provider.addMantra(preset.toMantra());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${preset.name}')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
