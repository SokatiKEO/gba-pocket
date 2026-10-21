import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../models/gba_types.dart';
import 'rom_storage_interface.dart';

class GbaRomStorageImpl implements GbaRomStorage {
  Directory? _romsDir;

  Future<Directory> _getDir() async {
    if (_romsDir != null) return _romsDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/gba_custom_roms');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _romsDir = dir;
    return dir;
  }

  @override
  Future<void> init() async {
    try {
      await _getDir();
    } catch (_) {}
  }

  @override
  Future<void> saveRom(SavedRomEntry entry, Uint8List bytes) async {
    final dir = await _getDir();
    final file = File('${dir.path}/${entry.id}.gba');
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> loadRomBytes(String id) async {
    final dir = await _getDir();
    final file = File('${dir.path}/$id.gba');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> deleteRom(String id) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/$id.gba');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Directory? _statesDir;

  Future<Directory> _getStatesDir() async {
    if (_statesDir != null) return _statesDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/gba_states');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _statesDir = dir;
    return dir;
  }

  @override
  Future<void> saveStateData(String romId, int slot, String stateData) async {
    try {
      final dir = await _getStatesDir();
      final file = File('${dir.path}/${romId}_slot_$slot.json');
      await file.writeAsString(stateData, flush: true);
    } catch (_) {}
  }

  @override
  Future<String?> loadStateData(String romId, int slot) async {
    try {
      final dir = await _getStatesDir();
      final file = File('${dir.path}/${romId}_slot_$slot.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> deleteStateData(String romId, int slot) async {
    try {
      final dir = await _getStatesDir();
      final file = File('${dir.path}/${romId}_slot_$slot.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
