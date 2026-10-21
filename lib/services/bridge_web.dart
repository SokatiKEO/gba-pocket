import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import '../models/gba_types.dart';
import 'bridge_interface.dart';

class GbaBridgeImpl implements GbaPlatformBridge {
  @override
  void Function(int fps)? onFpsUpdate;
  @override
  void Function(String title)? onRomLoaded;
  @override
  void Function(String error)? onError;
  @override
  void Function(String stateJson, int slot, String? romId)? onSaveStateExported;

  JSObject? get _bridge {
    final gbaBridge = web.window.getProperty('GbaBridge'.toJS);
    if (gbaBridge.isA<JSObject>()) {
      return gbaBridge as JSObject;
    }
    return null;
  }

  @override
  void init(dynamic viewTarget) {
    web.window.setProperty(
      'onGbaFpsUpdate'.toJS,
      ((JSNumber fps) {
        onFpsUpdate?.call(fps.toDartInt);
      }).toJS,
    );

    web.window.setProperty(
      'onGbaRomLoaded'.toJS,
      ((JSString title) {
        onRomLoaded?.call(title.toDart);
      }).toJS,
    );

    web.window.setProperty(
      'onGbaError'.toJS,
      ((JSString err) {
        onError?.call(err.toDart);
      }).toJS,
    );

    if (viewTarget != null) {
      _bridge?.callMethod('init'.toJS, viewTarget as JSAny);
    } else {
      _bridge?.callMethod('init'.toJS);
    }
  }

  @override
  void buttonDown(GbaButton btn) {
    _bridge?.callMethod('buttonDown'.toJS, btn.jsKeyName.toJS);
  }

  @override
  void buttonUp(GbaButton btn) {
    _bridge?.callMethod('buttonUp'.toJS, btn.jsKeyName.toJS);
  }

  @override
  void loadRomUrl(String url, String title) {
    _bridge?.callMethod('loadRomFromUrl'.toJS, url.toJS, title.toJS);
  }

  @override
  void loadRomBase64(String base64, String title) {
    _bridge?.callMethod('loadRomBase64'.toJS, base64.toJS, title.toJS);
  }

  @override
  void play() {
    _bridge?.callMethod('play'.toJS);
  }

  @override
  void pause() {
    _bridge?.callMethod('pause'.toJS);
  }

  @override
  void reset() {
    _bridge?.callMethod('reset'.toJS);
  }

  @override
  void setVolume(double vol) {
    _bridge?.callMethod('setVolume'.toJS, vol.toJS);
  }

  @override
  void setMute(bool muted) {
    _bridge?.callMethod('setMute'.toJS, muted.toJS);
  }

  @override
  void setSpeed(double multiplier) {
    _bridge?.callMethod('setSpeed'.toJS, multiplier.toJS);
  }

  @override
  void saveState(int slot, {String? romId}) {
    final result = _bridge?.callMethod('exportStateString'.toJS, slot.toJS);
    if (result != null && result.isA<JSString>()) {
      final jsonStr = (result as JSString).toDart;
      if (jsonStr.isNotEmpty) {
        onSaveStateExported?.call(jsonStr, slot, romId);
      }
    } else {
      _bridge?.callMethod('saveState'.toJS, slot.toJS);
    }
  }

  @override
  void loadState(int slot) {
    _bridge?.callMethod('loadState'.toJS, slot.toJS);
  }

  @override
  void loadStateJson(String stateJson) {
    _bridge?.callMethod('importStateString'.toJS, stateJson.toJS);
  }

  @override
  void setFilter(String filter) {
    final container = web.document.getElementById('gba-container');
    if (container != null) {
      container.className = filter == 'lcd' ? 'filter-lcd' : '';
    }
  }
}

GbaPlatformBridge createPlatformBridge() => GbaBridgeImpl();
