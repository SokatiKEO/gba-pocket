import 'dart:convert';
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
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/$id.gba');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        for (final e in entities) {
          if (e is File) {
            final name = e.uri.pathSegments.last;
            if (name == '$id.gba' || name.startsWith(id)) {
              return await e.readAsBytes();
            }
          }
        }
      }
    } catch (_) {}
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

  @override
  Future<void> saveLibrary(List<SavedRomEntry> entries) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/library.json');
      final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonStr, flush: true);
    } catch (_) {}
  }

  @override
  Future<List<SavedRomEntry>> loadLibrary() async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/library.json');
      final Map<String, SavedRomEntry> romMap = {};

      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final list = jsonDecode(content) as List<dynamic>;
          for (final item in list) {
            try {
              final entry = SavedRomEntry.fromJson(item as Map<String, dynamic>);
              romMap[entry.id] = entry;
            } catch (_) {}
          }
        } catch (_) {}
      }

      // Always scan directory for all saved ROM binaries to ensure persistence
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        for (final entity in entities) {
          if (entity is File) {
            final pathLower = entity.path.toLowerCase();
            if (pathLower.endsWith('.gba') || pathLower.endsWith('.agb') || pathLower.endsWith('.bin')) {
              final fileName = entity.uri.pathSegments.last;
              final id = fileName.replaceAll(RegExp(r'\.(gba|agb|bin)$', caseSensitive: false), '');
              if (!romMap.containsKey(id)) {
                final cleanTitle = id.replaceAll(RegExp(r'^\d+_'), '').replaceAll('_', ' ');
                romMap[id] = SavedRomEntry(
                  id: id,
                  title: cleanTitle.isEmpty ? 'Custom ROM' : cleanTitle,
                  fileName: fileName,
                  sizeBytes: entity.lengthSync(),
                  addedAt: DateTime.now(),
                );
              }
            }
          }
        }
      }

      final result = romMap.values.toList();
      if (result.isNotEmpty) {
        await saveLibrary(result);
      }
      return result;
    } catch (_) {}
    return [];
  }

  @override
  Future<void> saveActiveGameMetadata(Map<String, dynamic> data) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/active_game.json');
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> loadActiveGameMetadata() async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/active_game.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
