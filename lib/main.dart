import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/mantra.dart';
import 'models/daily_completion.dart';
import 'models/journal_entry.dart';
import 'models/commitment.dart';
import 'models/session.dart';
import 'providers/mantra_provider.dart';
import 'providers/commitment_provider.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/haptic_feedback.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters. Guarded so a hot restart, which re-runs main() against
  // an already-initialised Hive, doesn't throw on re-registration.
  _registerAdapter(0, MantraAdapter());
  _registerAdapter(1, SessionAdapter());
  _registerAdapter(2, DailyCompletionAdapter());
  _registerAdapter(3, JournalEntryAdapter());
  _registerAdapter(4, CommitmentAdapter());

  // Cache the device's vibrator capability once, so bead taps don't each
  // pay for a platform channel round-trip.
  await HapticFeedbackService.init();
  await NotificationService.init();

  runApp(const MyApp());
}

void _registerAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MantraProvider()..init()),
        ChangeNotifierProvider(create: (_) => SessionProvider()..init()),
        ChangeNotifierProvider(create: (_) => CommitmentProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Japamala',
            theme: themeProvider.lightThemeData,
            darkTheme: themeProvider.darkThemeData,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
