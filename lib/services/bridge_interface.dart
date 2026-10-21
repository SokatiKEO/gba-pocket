import '../models/gba_types.dart';

abstract class GbaPlatformBridge {
  void Function(int fps)? onFpsUpdate;
  void Function(String title)? onRomLoaded;
  void Function(String error)? onError;
  void Function(String stateJson, int slot, String? romId)? onSaveStateExported;

  void init(dynamic viewTarget);
  void buttonDown(GbaButton btn);
  void buttonUp(GbaButton btn);
  void loadRomUrl(String url, String title);
  void loadRomBase64(String base64, String title);
  void play();
  void pause();
  void reset();
  void setVolume(double vol);
  void setMute(bool muted);
  void setSpeed(double multiplier);
  void saveState(int slot, {String? romId});
  void loadState(int slot);
  void loadStateJson(String stateJson);
  void setFilter(String filter);
}
