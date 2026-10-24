import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/gba_types.dart';
import 'rom_storage_interface.dart';

class GbaRomStorageImpl implements GbaRomStorage {
  Directory? _romsDir;
  Directory? _statesDir;

  Future<List<Directory>> _getAllCandidateDirs() async {
    final dirs = <Directory>[];
    try {
      final docs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${docs.path}/gba_custom_roms'));
    } catch (_) {}
    try {
      final support = await getApplicationSupportDirectory();
      dirs.add(Directory('${support.path}/gba_custom_roms'));
    } catch (_) {}
    return dirs;
  }

  Future<Directory> _getDir() async {
    if (_romsDir != null && _romsDir!.existsSync()) return _romsDir!;
    Directory? chosen;
    try {
      final docs = await getApplicationDocumentsDirectory();
      chosen = Directory('${docs.path}/gba_custom_roms');
    } catch (_) {
      try {
        final support = await getApplicationSupportDirectory();
        chosen = Directory('${support.path}/gba_custom_roms');
      } catch (_) {}
    }
    chosen ??= Directory('gba_custom_roms');
    if (!chosen.existsSync()) {
      await chosen.create(recursive: true);
    }
    _romsDir = chosen;
    return chosen;
  }

  Future<void> _atomicWriteString(File targetFile, String content) async {
    final tempFile = File('${targetFile.path}.tmp_${DateTime.now().microsecondsSinceEpoch}');
    try {
      await tempFile.writeAsString(content, flush: true);
      if (await targetFile.exists()) {
        final backupFile = File('${targetFile.path}.bak');
        try {
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
          await targetFile.copy(backupFile.path);
        } catch (_) {}
      }
      await tempFile.rename(targetFile.path);
    } catch (e) {
      debugPrint('Atomic write rename fallback: $e');
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      try {
        await targetFile.writeAsString(content, flush: true);
      } catch (_) {}
    }
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
      final candidateDirs = await _getAllCandidateDirs();
      final cleanId = id.replaceAll(RegExp(r'\.(gba|agb|bin)$', caseSensitive: false), '');

      for (final dir in candidateDirs) {
        if (!await dir.exists()) continue;

        final exact = File('${dir.path}/$cleanId.gba');
        if (await exact.exists()) {
          return await exact.readAsBytes();
        }

        final direct = File('${dir.path}/$id');
        if (await direct.exists()) {
          return await direct.readAsBytes();
        }

        try {
          final entities = await dir.list().toList();
          for (final e in entities) {
            if (e is File) {
              final name = e.path.split(RegExp(r'[/\\]')).last;
              if (name == '$cleanId.gba' || name == '$id.gba' || name.startsWith(cleanId)) {
                return await e.readAsBytes();
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> deleteRom(String id) async {
    try {
      final candidateDirs = await _getAllCandidateDirs();
      final cleanId = id.replaceAll(RegExp(r'\.(gba|agb|bin)$', caseSensitive: false), '');
      for (final dir in candidateDirs) {
        if (!await dir.exists()) continue;
        final file = File('${dir.path}/$cleanId.gba');
        if (await file.exists()) {
          await file.delete();
        }
        final direct = File('${dir.path}/$id');
        if (await direct.exists()) {
          await direct.delete();
        }
      }
    } catch (_) {}
  }

  Future<Directory> _getStatesDir() async {
    if (_statesDir != null && _statesDir!.existsSync()) return _statesDir!;
    Directory? chosen;
    try {
      final docs = await getApplicationDocumentsDirectory();
      chosen = Directory('${docs.path}/gba_states');
    } catch (_) {
      try {
        final support = await getApplicationSupportDirectory();
        chosen = Directory('${support.path}/gba_states');
      } catch (_) {}
    }
    chosen ??= Directory('gba_states');
    if (!chosen.existsSync()) {
      await chosen.create(recursive: true);
    }
    _statesDir = chosen;
    return chosen;
  }

  @override
  Future<void> saveStateData(String romId, int slot, String stateData) async {
    try {
      final dir = await _getStatesDir();
      final file = File('${dir.path}/${romId}_slot_$slot.json');
      await _atomicWriteString(file, stateData);
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
      final bakFile = File('${dir.path}/${romId}_slot_$slot.json.bak');
      if (await bakFile.exists()) {
        return await bakFile.readAsString();
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
      final bakFile = File('${dir.path}/${romId}_slot_$slot.json.bak');
      if (await bakFile.exists()) {
        await bakFile.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> saveLibrary(List<SavedRomEntry> entries) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/library.json');
      final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
      await _atomicWriteString(file, jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<SavedRomEntry>> loadLibrary() async {
    final Map<String, SavedRomEntry> romMap = {};
    try {
      final candidateDirs = await _getAllCandidateDirs();

      for (final dir in candidateDirs) {
        if (!await dir.exists()) continue;

        // 1. Try reading library.json
        final file = File('${dir.path}/library.json');
        if (await file.exists()) {
          try {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              final list = jsonDecode(content) as List<dynamic>;
              for (final item in list) {
                try {
                  final entry = SavedRomEntry.fromJson(item as Map<String, dynamic>);
                  romMap[entry.id] = entry;
                } catch (_) {}
              }
            }
          } catch (_) {
            // Backup file check
            try {
              final bakFile = File('${dir.path}/library.json.bak');
              if (await bakFile.exists()) {
                final content = await bakFile.readAsString();
                final list = jsonDecode(content) as List<dynamic>;
                for (final item in list) {
                  try {
                    final entry = SavedRomEntry.fromJson(item as Map<String, dynamic>);
                    romMap[entry.id] = entry;
                  } catch (_) {}
                }
              }
            } catch (_) {}
          }
        }

        // 2. Scan directory for any saved ROM binaries to ensure persistence
        try {
          final entities = await dir.list().toList();
          for (final entity in entities) {
            if (entity is File) {
              final pathLower = entity.path.toLowerCase();
              if (pathLower.endsWith('.gba') || pathLower.endsWith('.agb') || pathLower.endsWith('.bin')) {
                final fileName = entity.path.split(RegExp(r'[/\\]')).last;
                final id = fileName.replaceAll(RegExp(r'\.(gba|agb|bin)$', caseSensitive: false), '');
                if (!romMap.containsKey(id)) {
                  int size = 0;
                  try {
                    size = await entity.length();
                  } catch (_) {}

                  String cleanTitle = id;
                  if (cleanTitle.toLowerCase().startsWith('rom_')) {
                    cleanTitle = cleanTitle.substring(4);
                  }
                  cleanTitle = cleanTitle.replaceAll(RegExp(r'^\d+_'), '').replaceAll('_', ' ').trim();
                  if (cleanTitle.isNotEmpty) {
                    cleanTitle = cleanTitle.split(' ').map((w) {
                      if (w.isEmpty) return '';
                      return '${w[0].toUpperCase()}${w.substring(1)}';
                    }).join(' ');
                  }

                  romMap[id] = SavedRomEntry(
                    id: id,
                    title: cleanTitle.isEmpty ? 'Custom ROM' : cleanTitle,
                    fileName: fileName,
                    sizeBytes: size,
                    addedAt: DateTime.now(),
                  );
                }
              }
            }
          }
        } catch (_) {}
      }

      final result = romMap.values.toList();
      if (result.isNotEmpty) {
        await saveLibrary(result);
      }
      return result;
    } catch (_) {}
    return romMap.values.toList();
  }

  @override
  Future<void> saveActiveGameMetadata(Map<String, dynamic> data) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/active_game.json');
      await _atomicWriteString(file, jsonEncode(data));
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> loadActiveGameMetadata() async {
    try {
      final candidateDirs = await _getAllCandidateDirs();
      for (final dir in candidateDirs) {
        if (!await dir.exists()) continue;
        final file = File('${dir.path}/active_game.json');
        if (await file.exists()) {
          try {
            final content = await file.readAsString();
            return jsonDecode(content) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }
}
