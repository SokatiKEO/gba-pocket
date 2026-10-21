import 'package:flutter_test/flutter_test.dart';
import 'package:gba_emulator/main.dart';
import 'package:gba_emulator/models/gba_types.dart';
import 'package:gba_emulator/services/gba_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GBA Emulator app loads smoke test', (WidgetTester tester) async {
    final controller = GbaController();
    await tester.pumpWidget(GbaEmulatorApp(controller: controller));
    expect(find.text('GAME BOY '), findsOneWidget);
  });

  test('SavedRomEntry serialization and formattedSize test', () {
    final entry = SavedRomEntry(
      id: 'rom_123',
      title: 'Pokemon Emerald',
      fileName: 'pokemon_emerald.gba',
      sizeBytes: 16 * 1024 * 1024,
      addedAt: DateTime(2026, 1, 1),
    );

    expect(entry.formattedSize, '16.0 MB');

    final json = entry.toJson();
    final reconstructed = SavedRomEntry.fromJson(json);

    expect(reconstructed.id, 'rom_123');
    expect(reconstructed.title, 'Pokemon Emerald');
    expect(reconstructed.fileName, 'pokemon_emerald.gba');
    expect(reconstructed.sizeBytes, 16 * 1024 * 1024);
  });

  test('Active game persistence across restarts test', () async {
    SharedPreferences.setMockInitialValues({
      'gba_active_rom_id': 'waimanu',
      'gba_active_rom_type': 'builtIn',
      'gba_active_rom_title': 'Waimanu',
      'gba_selected_save_slot': 2,
    });

    final controller = GbaController();
    // Allow async loadPreferences to run
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.activeRomId, 'waimanu');
    expect(controller.activeRomType, 'builtIn');
    expect(controller.currentRomTitle, 'Waimanu');
    expect(controller.selectedSaveSlot, 2);
    expect(controller.isRestoring, true);
    controller.dispose();
  });
}

