import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:japamala/models/daily_completion.dart';
import 'package:japamala/models/mantra.dart';
import 'package:japamala/providers/mantra_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('japamala_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MantraAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyCompletionAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<MantraProvider> openProvider() async {
    final provider = MantraProvider();
    await provider.init();
    return provider;
  }

  test('rapid un-awaited increments are all counted', () async {
    final provider = await openProvider();
    final mantra = Mantra.create(name: 'Om', targetCount: 108);
    await provider.addMantra(mantra);

    // Taps arriving faster than Hive can flush to disk. The UI does not await
    // these, so the read-modify-write must not go through the box.
    final taps = [
      for (var i = 0; i < 50; i++) provider.incrementCount(mantra.id),
    ];

    // The count is visible immediately, before any write resolves.
    expect(provider.getMantraById(mantra.id)!.currentCount, 50);

    await Future.wait(taps);
    expect(provider.getMantraById(mantra.id)!.currentCount, 50);
  });

  test('counts survive a restart', () async {
    final provider = await openProvider();
    final mantra = Mantra.create(name: 'Gayatri', targetCount: 108);
    await provider.addMantra(mantra);

    await Future.wait([
      for (var i = 0; i < 20; i++) provider.incrementCount(mantra.id),
    ]);
    await Hive.close();

    final reopened = await openProvider();
    expect(reopened.getMantraById(mantra.id)!.currentCount, 20);
  });

  test('resetCount zeroes the mantra', () async {
    final provider = await openProvider();
    final mantra = Mantra.create(name: 'Om', targetCount: 3);
    await provider.addMantra(mantra);

    await provider.incrementCount(mantra.id);
    await provider.incrementCount(mantra.id);
    await provider.resetCount(mantra.id);

    expect(provider.getMantraById(mantra.id)!.currentCount, 0);
  });

  test('a mantra is complete only on the final bead', () async {
    final provider = await openProvider();
    final mantra = Mantra.create(name: 'Om', targetCount: 3);
    await provider.addMantra(mantra);

    await provider.incrementCount(mantra.id);
    expect(provider.getMantraById(mantra.id)!.isCompleted, isFalse);
    await provider.incrementCount(mantra.id);
    expect(provider.getMantraById(mantra.id)!.isCompleted, isFalse);
    await provider.incrementCount(mantra.id);
    expect(provider.getMantraById(mantra.id)!.isCompleted, isTrue);
  });
}
