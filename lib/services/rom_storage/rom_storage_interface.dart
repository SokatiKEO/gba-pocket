import 'dart:typed_data';
import '../../models/gba_types.dart';

abstract class GbaRomStorage {
  Future<void> init();
  Future<void> saveRom(SavedRomEntry entry, Uint8List bytes);
  Future<Uint8List?> loadRomBytes(String id);
  Future<void> deleteRom(String id);

  Future<void> saveStateData(String romId, int slot, String stateData);
  Future<String?> loadStateData(String romId, int slot);
  Future<void> deleteStateData(String romId, int slot);

  Future<void> saveLibrary(List<SavedRomEntry> entries);
  Future<List<SavedRomEntry>> loadLibrary();
  Future<void> saveActiveGameMetadata(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> loadActiveGameMetadata();
}
