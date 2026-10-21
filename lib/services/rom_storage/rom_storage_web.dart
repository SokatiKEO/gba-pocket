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
}
