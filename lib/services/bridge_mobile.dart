import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
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

  WebViewController? _controller;

  @override
  void init(dynamic viewTarget) {
    if (viewTarget is WebViewController) {
      _controller = viewTarget;
    }
  }

  void setController(WebViewController controller) {
    _controller = controller;
  }

  void handleIncomingMessage(String rawJson) {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final type = map['type'] as String?;
      if (type == 'fps') {
        final fps = map['value'] as int? ?? 60;
        onFpsUpdate?.call(fps);
      } else if (type == 'romLoaded') {
        final title = map['title'] as String? ?? 'GBA Game';
        onRomLoaded?.call(title);
      } else if (type == 'error') {
        onError?.call(map['message'] as String? ?? 'Emulation error');
      } else if (type == 'saveStateResult') {
        final stateData = map['stateData'] as String?;
        final slot = map['slot'] as int? ?? 1;
        final romId = map['romId'] as String?;
        if (stateData != null && stateData.isNotEmpty) {
          onSaveStateExported?.call(stateData, slot, romId);
        }
      }
    } catch (_) {}
  }

  void _send(Map<String, dynamic> data) {
    if (_controller == null) return;
    final jsonStr = jsonEncode(data);
    _controller!.runJavaScript('window.handleFlutterMessage($jsonStr);');
  }

  @override
  void buttonDown(GbaButton btn) {
    _send({'action': 'buttonDown', 'button': btn.jsKeyName});
  }

  @override
  void buttonUp(GbaButton btn) {
    _send({'action': 'buttonUp', 'button': btn.jsKeyName});
  }

  @override
  void loadRomUrl(String url, String title) {
    _send({'action': 'loadRomUrl', 'url': url, 'title': title});
  }

  @override
  void loadRomBase64(String base64, String title) {
    _send({'action': 'loadRomBase64', 'base64': base64, 'title': title});
  }

  @override
  void play() {
    _send({'action': 'play'});
  }

  @override
  void pause() {
    _send({'action': 'pause'});
  }

  @override
  void reset() {
    _send({'action': 'reset'});
  }

  @override
  void setVolume(double vol) {
    _send({'action': 'setVolume', 'volume': vol});
  }

  @override
  void setMute(bool muted) {
    _send({'action': 'setMute', 'muted': muted});
  }

  @override
  void setSpeed(double multiplier) {
    _send({'action': 'setSpeed', 'multiplier': multiplier});
  }

  @override
  void saveState(int slot, {String? romId}) {
    _send({'action': 'saveState', 'slot': slot, 'romId': ?romId});
  }

  @override
  void loadState(int slot) {
    _send({'action': 'loadState', 'slot': slot});
  }

  @override
  void loadStateJson(String stateJson) {
    _send({'action': 'loadStateJson', 'stateJson': stateJson});
  }

  @override
  void setFilter(String filter) {
    _send({'action': 'setFilter', 'filter': filter});
  }
}

GbaPlatformBridge createPlatformBridge() => GbaBridgeImpl();
