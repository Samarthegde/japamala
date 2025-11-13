import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/mantra.dart';
import 'models/daily_completion.dart';
import 'models/journal_entry.dart';
import 'models/session.dart';
import 'providers/mantra_provider.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(MantraAdapter());
  Hive.registerAdapter(DailyCompletionAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(SessionAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MantraProvider()..init()),
        // ChangeNotifierProvider(create: (_) => SessionProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Japamala',
            theme: themeProvider.currentThemeData,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
