import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gba_emulator/models/gba_types.dart';
import 'package:gba_emulator/services/gba_controller.dart';
import 'package:gba_emulator/services/rom_storage/rom_storage_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gba_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('GbaRomStorageImpl saveRom, saveLibrary, and loadLibrary test', () async {
    final storage = GbaRomStorageImpl();
    final entry = SavedRomEntry(
      id: 'rom_emerald',
      title: 'Pokemon Emerald',
      fileName: 'Pokemon Emerald.gba',
      sizeBytes: 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    // Save ROM bytes
    final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    await storage.saveRom(entry, bytes);

    // Save library
    await storage.saveLibrary([entry]);

    // Now create a NEW storage instance (simulating app restart)
    final storage2 = GbaRomStorageImpl();
    final loaded = await storage2.loadLibrary();

    expect(loaded.length, 1);
    expect(loaded.first.id, 'rom_emerald');
    expect(loaded.first.title, 'Pokemon Emerald');

    final loadedBytes = await storage2.loadRomBytes('rom_emerald');
    expect(loadedBytes, isNotNull);
    expect(loadedBytes!.length, 1024);
  });

  test('GbaController custom ROM persistence across app restart', () async {
    final entry = SavedRomEntry(
      id: 'rom_emerald',
      title: 'Pokemon Emerald',
      fileName: 'Pokemon Emerald.gba',
      sizeBytes: 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    // Initial run: ROM is saved
    final storage = GbaRomStorageImpl();
    final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    await storage.saveRom(entry, bytes);
    await storage.saveLibrary([entry]);

    SharedPreferences.setMockInitialValues({
      'gba_saved_roms_list': [jsonEncode(entry.toJson())],
      'gba_active_rom_id': 'rom_emerald',
      'gba_active_rom_type': 'custom',
      'gba_active_rom_title': 'Pokemon Emerald',
    });

    // App launch (simulated restart)
    final controller = GbaController();
    await controller.ensurePreferencesLoaded();

    expect(controller.savedRoms.length, 1);
    expect(controller.savedRoms.first.title, 'Pokemon Emerald');
    expect(controller.activeRomId, 'rom_emerald');
    expect(controller.activeRomType, 'custom');
    expect(controller.currentRomTitle, 'Pokemon Emerald');

    controller.dispose();
  });

  test('GbaController recovers custom ROM from disk storage when SharedPreferences is cleared', () async {
    final entry = SavedRomEntry(
      id: 'rom_emerald',
      title: 'Pokemon Emerald',
      fileName: 'Pokemon Emerald.gba',
      sizeBytes: 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    // Initial run: ROM is saved to disk
    final storage = GbaRomStorageImpl();
    final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    await storage.saveRom(entry, bytes);
    await storage.saveLibrary([entry]);

    // SharedPreferences was CLEARED!
    SharedPreferences.setMockInitialValues({});

    final controller = GbaController();
    await controller.ensurePreferencesLoaded();

    expect(controller.savedRoms.length, 1);
    expect(controller.savedRoms.first.title, 'Pokemon Emerald');

    controller.dispose();
  });

  test('GbaController recovers custom ROM from .gba file alone when library.json is missing', () async {
    final entry = SavedRomEntry(
      id: 'rom_emerald',
      title: 'Pokemon Emerald',
      fileName: 'Pokemon Emerald.gba',
      sizeBytes: 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    // Only write the .gba binary file, NO library.json
    final storage = GbaRomStorageImpl();
    final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    await storage.saveRom(entry, bytes);

    // SharedPreferences is empty
    SharedPreferences.setMockInitialValues({});

    final controller = GbaController();
    await controller.ensurePreferencesLoaded();

    expect(controller.savedRoms.length, 1);
    expect(controller.savedRoms.first.id, 'rom_emerald');

    controller.dispose();
  });

  test('SavedRomEntry.fromJson safely parses edge cases and unexpected types', () {
    // Double / num sizeBytes
    final entry1 = SavedRomEntry.fromJson({
      'id': 'rom_test1',
      'title': 'Test ROM 1',
      'fileName': 'test1.gba',
      'sizeBytes': 2048.0,
      'addedAt': 1710000000000,
    });
    expect(entry1.sizeBytes, 2048);
    expect(entry1.id, 'rom_test1');
    expect(entry1.title, 'Test ROM 1');

    // Missing id and title fallback safely
    final entry2 = SavedRomEntry.fromJson({});
    expect(entry2.id.isNotEmpty, true);
    expect(entry2.title, 'Custom ROM');
    expect(entry2.sizeBytes, 0);
  });

  test('GbaRomStorageImpl recovers from library.json.bak when library.json is corrupt', () async {
    final storage = GbaRomStorageImpl();
    final entry = SavedRomEntry(
      id: 'rom_emerald',
      title: 'Pokemon Emerald',
      fileName: 'Pokemon Emerald.gba',
      sizeBytes: 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    await storage.saveRom(entry, Uint8List(100));
    await storage.saveLibrary([entry]);

    // Force corrupt library.json, but keep library.json.bak
    final romsDir = Directory('${tempDir.path}/gba_custom_roms');
    final libFile = File('${romsDir.path}/library.json');
    final bakFile = File('${romsDir.path}/library.json.bak');
    expect(await bakFile.exists() || await libFile.exists(), true);

    // Corrupt library.json
    await libFile.writeAsString('{ invalid truncated json ...');

    final storage2 = GbaRomStorageImpl();
    final loaded = await storage2.loadLibrary();
    expect(loaded.isNotEmpty, true);
    expect(loaded.any((r) => r.id == 'rom_emerald'), true);
  });

  test('GbaController _savePreferences never destroys saved ROMs if in-memory list was empty', () async {
    final entry = SavedRomEntry(
      id: 'rom_emerald',
      title: 'Pokemon Emerald',
      fileName: 'Pokemon Emerald.gba',
      sizeBytes: 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    SharedPreferences.setMockInitialValues({
      'gba_saved_roms_list': [jsonEncode(entry.toJson())],
    });

    final controller = GbaController();
    await controller.ensurePreferencesLoaded();

    expect(controller.savedRoms.length, 1);

    // Set volume (which calls _savePreferences())
    controller.setVolume(0.8);
    await Future.delayed(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('gba_saved_roms_list');
    expect(list, isNotNull);
    expect(list!.length, 1);

    controller.dispose();
  });
}
