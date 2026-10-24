import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../../models/gba_types.dart';
import 'rom_storage_interface.dart';

class GbaRomStorageImpl implements GbaRomStorage {
  JSObject? get _db {
    final romDb = web.window.getProperty('GbaRomDb'.toJS);
    if (romDb.isA<JSObject>()) {
      return romDb as JSObject;
    }
    return null;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> saveRom(SavedRomEntry entry, Uint8List bytes) async {
    final db = _db;
    if (db == null) return;
    try {
      final b64 = base64Encode(bytes);
      final promise = db.callMethod('saveRom'.toJS, entry.id.toJS, b64.toJS) as JSPromise;
      await promise.toDart;
    } catch (_) {}
  }

  @override
  Future<Uint8List?> loadRomBytes(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      final promise = db.callMethod('loadRom'.toJS, id.toJS) as JSPromise;
      final result = await promise.toDart;
      if (result == null || !result.isA<JSString>()) return null;
      final b64 = (result as JSString).toDart;
      if (b64.isEmpty) return null;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteRom(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      final promise = db.callMethod('deleteRom'.toJS, id.toJS) as JSPromise;
      await promise.toDart;
    } catch (_) {}
  }

  @override
  Future<void> saveStateData(String romId, int slot, String stateData) async {
    try {
      final key = 'gba_state_${romId}_slot_$slot';
      web.window.localStorage.setItem(key, stateData);
    } catch (_) {}
  }

  @override
  Future<String?> loadStateData(String romId, int slot) async {
    try {
      final key = 'gba_state_${romId}_slot_$slot';
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteStateData(String romId, int slot) async {
    try {
      final key = 'gba_state_${romId}_slot_$slot';
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }

  @override
  Future<void> saveLibrary(List<SavedRomEntry> entries) async {
    try {
      final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
      web.window.localStorage.setItem('gba_library_backup', jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<SavedRomEntry>> loadLibrary() async {
    final Map<String, SavedRomEntry> romMap = {};
    try {
      final str = web.window.localStorage.getItem('gba_library_backup');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List<dynamic>;
        for (final item in list) {
          try {
            final entry = SavedRomEntry.fromJson(item as Map<String, dynamic>);
            romMap[entry.id] = entry;
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Check IndexedDB keys as fallback to ensure ROMs are never lost
    final db = _db;
    if (db != null) {
      try {
        final promise = db.callMethod('getAllRomKeys'.toJS) as JSPromise;
        final result = await promise.toDart;
        if (result != null && result.isA<JSArray<JSString>>()) {
          final jsArr = result as JSArray<JSString>;
          final length = jsArr.length;
          for (int i = 0; i < length; i++) {
            final keyObj = jsArr[i];
            final id = keyObj.toDart;
            if (!romMap.containsKey(id)) {
              String title = id.startsWith('rom_') ? id.substring(4) : id;
              title = title.replaceAll('_', ' ').trim();
              if (title.isNotEmpty) {
                title = title.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
              }
              romMap[id] = SavedRomEntry(
                id: id,
                title: title.isEmpty ? 'Custom ROM' : title,
                fileName: '$title.gba',
                sizeBytes: 0,
                addedAt: DateTime.now(),
              );
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
  }

  @override
  Future<void> saveActiveGameMetadata(Map<String, dynamic> data) async {
    try {
      web.window.localStorage.setItem('gba_active_game_backup', jsonEncode(data));
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> loadActiveGameMetadata() async {
    try {
      final str = web.window.localStorage.getItem('gba_active_game_backup');
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
