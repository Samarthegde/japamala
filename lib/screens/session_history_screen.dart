import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/mantra_provider.dart';
import '../providers/session_provider.dart';
import '../models/session.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
      ),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete some mantra rounds to see your history',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: session.completed
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      session.completed ? Icons.check : Icons.play_arrow,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: Text(mantra?.name ?? 'Unknown Mantra'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${session.count} beads • ${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s'),
                      Text(
                        DateFormat('MMM d, h:mm a').format(session.endTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
}
