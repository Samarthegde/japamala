import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      body: Consumer2<MantraProvider, SessionProvider>(
        builder: (context, mantraProvider, sessionProvider, child) {
          final allSessions = sessionProvider.getAllSessions();

          if (allSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Japa, breathing and meditation all show up here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSessions.length,
            itemBuilder: (context, index) {
              final session = allSessions[index];
              final mantra = mantraProvider.getMantraById(session.mantraId);

              // Breathing and meditation have no mantra behind them, so they
              // carry their own title.
              final title = session.kind == SessionKind.japa
                  ? (mantra?.name ?? 'Deleted mantra')
                  : (session.title ?? session.kind.label);

              final duration =
                  '${session.duration.inMinutes}m '
                  '${session.duration.inSeconds % 60}s';
              final countLabel = session.countLabel;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: session.completed
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _iconFor(session.kind),
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countLabel.isEmpty
                            ? duration
                            : '$countLabel • $duration',
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(session.endTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  trailing: session.completed
                      ? const Icon(Icons.emoji_events, color: Colors.green)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  static IconData _iconFor(SessionKind kind) {
    switch (kind) {
      case SessionKind.japa:
        return Icons.blur_circular;
      case SessionKind.breathing:
        return Icons.air;
      case SessionKind.meditation:
        return Icons.self_improvement;
    }
  }
}
