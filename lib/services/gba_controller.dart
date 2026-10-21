import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gba_types.dart';
import 'bridge.dart';
import 'rom_storage/rom_storage.dart';

class GbaController extends ChangeNotifier {
  late final GbaPlatformBridge _bridge;
  final GbaRomStorage _romStorage = GbaRomStorageImpl();

  bool _isInitialized = false;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isRestoring = false;
  String _currentRomTitle = 'No Game Loaded';
  int _fps = 0;
  double _volume = 1.0;
  bool _isMuted = false;
  double _speed = 1.0;
  int _selectedSaveSlot = 1;
  GbaFilter _filter = GbaFilter.lcd;
  GbaSkin _skin = GbaSkin.allSkins.first;
  bool _hapticsEnabled = true;
  bool _landscapeFullscreen = false;
  List<SavedRomEntry> _savedRoms = [];

  String? _activeRomId;
  String? _activeRomType; // 'builtIn' or 'custom'
  String? _activeRomTitle;

  Timer? _autoSaveTimer;
  AppLifecycleListener? _lifecycleListener;
  final Completer<void> _preferencesLoadedCompleter = Completer<void>();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isRestoring => _isRestoring;
  String get currentRomTitle => _currentRomTitle;
  int get fps => _fps;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  double get speed => _speed;
  int get selectedSaveSlot => _selectedSaveSlot;
  GbaFilter get filter => _filter;
  GbaSkin get skin => _skin;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get landscapeFullscreen => _landscapeFullscreen;
  List<SavedRomEntry> get savedRoms => List.unmodifiable(_savedRoms);
  GbaPlatformBridge get bridge => _bridge;
  String? get activeRomId => _activeRomId;
  String? get activeRomType => _activeRomType;

  GbaController() {
    _bridge = createPlatformBridge();
    _bridge.onFpsUpdate = (fps) {
      _fps = fps;
      notifyListeners();
    };
    _bridge.onRomLoaded = (title) async {
      _isRunning = true;
      _isPaused = false;
      _isRestoring = false;
      _currentRomTitle = title;
      notifyListeners();
      await _tryRestoreSavedState();
    };
    _bridge.onSaveStateExported = (stateJson, slot, romId) async {
      final targetId = romId ?? _activeRomId;
      if (targetId != null) {
        await _romStorage.saveStateData(targetId, slot, stateJson);
      }
    };
    _romStorage.init();
    _loadPreferences();
    _initLifecycleListener();
  }

  void _initLifecycleListener() {
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.detached ||
            state == AppLifecycleState.hidden) {
          _handleAppBackgrounded();
        }
      },
    );
  }

  void _handleAppBackgrounded() {
    if (_isRunning && _activeRomId != null) {
      _bridge.saveState(0, romId: _activeRomId);
      _savePreferences();
    }
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_isRunning && !_isPaused && _activeRomId != null) {
        _bridge.saveState(0, romId: _activeRomId);
      }
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skinId = prefs.getString('gba_skin_id');
      if (skinId != null) {
        final found = GbaSkin.allSkins.where((s) => s.id == skinId);
        if (found.isNotEmpty) {
          _skin = found.first;
        }
      }
      final filterIndex = prefs.getInt('gba_filter_index');
      if (filterIndex != null && filterIndex >= 0 && filterIndex < GbaFilter.values.length) {
        _filter = GbaFilter.values[filterIndex];
      }
      _volume = prefs.getDouble('gba_volume') ?? 1.0;
      _hapticsEnabled = prefs.getBool('gba_haptics') ?? true;
      _landscapeFullscreen = prefs.getBool('gba_landscape_fullscreen') ?? false;
      _selectedSaveSlot = prefs.getInt('gba_selected_save_slot') ?? 1;

      final romsJsonList = prefs.getStringList('gba_saved_roms_list');
      if (romsJsonList != null) {
        _savedRoms = romsJsonList
            .map((str) {
              try {
                return SavedRomEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<SavedRomEntry>()
            .toList();
      }

      _activeRomId = prefs.getString('gba_active_rom_id');
      _activeRomType = prefs.getString('gba_active_rom_type');
      _activeRomTitle = prefs.getString('gba_active_rom_title');
      if (_activeRomTitle != null && _activeRomTitle!.isNotEmpty) {
        _currentRomTitle = _activeRomTitle!;
        _isRestoring = true;
      }

      notifyListeners();
    } catch (_) {
    } finally {
      if (!_preferencesLoadedCompleter.isCompleted) {
        _preferencesLoadedCompleter.complete();
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gba_skin_id', _skin.id);
      await prefs.setInt('gba_filter_index', _filter.index);
      await prefs.setDouble('gba_volume', _volume);
      await prefs.setBool('gba_haptics', _hapticsEnabled);
      await prefs.setBool('gba_landscape_fullscreen', _landscapeFullscreen);
      await prefs.setInt('gba_selected_save_slot', _selectedSaveSlot);

      final romsJsonList = _savedRoms.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList('gba_saved_roms_list', romsJsonList);

      if (_activeRomId != null) {
        await prefs.setString('gba_active_rom_id', _activeRomId!);
      } else {
        await prefs.remove('gba_active_rom_id');
      }
      if (_activeRomType != null) {
        await prefs.setString('gba_active_rom_type', _activeRomType!);
      } else {
        await prefs.remove('gba_active_rom_type');
      }
      if (_activeRomTitle != null) {
        await prefs.setString('gba_active_rom_title', _activeRomTitle!);
      } else {
        await prefs.remove('gba_active_rom_title');
      }
    } catch (_) {}
  }

  void initialize(dynamic viewTarget) {
    _bridge.init(viewTarget);
    if (!_isInitialized) {
      _isInitialized = true;
      _bridge.setVolume(_isMuted ? 0.0 : _volume);
      _bridge.setFilter(_filter.name);
      _restoreLastActiveGame();
    }
    notifyListeners();
  }

  Future<void> _restoreLastActiveGame() async {
    await _preferencesLoadedCompleter.future;

    if (_activeRomId == null || _activeRomType == null) {
      _isRestoring = false;
      notifyListeners();
      return;
    }

    if (_activeRomType == 'builtIn') {
      final rom = GbaRomInfo.builtInRoms.firstWhere(
        (r) => r.id == _activeRomId,
        orElse: () => GbaRomInfo.builtInRoms.first,
      );
      loadBuiltInRom(rom);
    } else if (_activeRomType == 'custom') {
      final matching = _savedRoms.where((r) => r.id == _activeRomId);
      if (matching.isNotEmpty) {
        await loadSavedRom(matching.first);
      } else {
        _isRestoring = false;
        notifyListeners();
      }
    } else {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _tryRestoreSavedState() async {
    if (_activeRomId == null) return;
    try {
      // 1. Check auto-save slot (slot 0) first
      String? stateJson = await _romStorage.loadStateData(_activeRomId!, 0);
      // 2. If no auto-save exists, check selected quick save slot (e.g. slot 1)
      if (stateJson == null || stateJson.isEmpty) {
        stateJson = await _romStorage.loadStateData(_activeRomId!, _selectedSaveSlot);
      }
      if (stateJson != null && stateJson.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 150));
        _bridge.loadStateJson(stateJson);
      }
    } catch (_) {}
  }

  void pressButton(GbaButton btn) {
    if (_hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    _bridge.buttonDown(btn);
  }

  void releaseButton(GbaButton btn) {
    _bridge.buttonUp(btn);
  }

  void loadBuiltInRom(GbaRomInfo rom) {
    if (_isRunning && _activeRomId != null && _activeRomId != rom.id) {
      _bridge.saveState(0, romId: _activeRomId);
    }
    _activeRomId = rom.id;
    _activeRomType = 'builtIn';
    _activeRomTitle = rom.title;
    _currentRomTitle = rom.title;
    _savePreferences();
    _startAutoSaveTimer();

    if (kIsWeb) {
      final relativeUrl = rom.id == 'waimanu' ? 'roms/waimanu.gba' : 'roms/yahtzee.gba';
      _bridge.loadRomUrl(relativeUrl, rom.title);
    } else {
      rootBundle.load(rom.assetPath).then((byteData) {
        final bytes = byteData.buffer.asUint8List();
        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, rom.title);
      }).catchError((err) {
        debugPrint('Error loading asset ROM: $err');
      });
    }
    _isRunning = true;
    _isPaused = false;
    notifyListeners();
  }

  Future<bool> pickAndLoadRom() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gba', 'bin', 'agb'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return false;

        final cleanTitle = file.name.replaceAll(RegExp(r'\.(gba|bin|agb)$', caseSensitive: false), '');
        final id = '${DateTime.now().millisecondsSinceEpoch}_${cleanTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

        final entry = SavedRomEntry(
          id: id,
          title: cleanTitle,
          fileName: file.name,
          sizeBytes: bytes.length,
          addedAt: DateTime.now(),
        );

        // Save binary to persistent storage
        await _romStorage.saveRom(entry, bytes);

        // Update in-memory and shared preferences list
        _savedRoms.removeWhere((r) => r.fileName == file.name || r.id == id);
        _savedRoms.insert(0, entry);

        if (_isRunning && _activeRomId != null && _activeRomId != id) {
          _bridge.saveState(0, romId: _activeRomId);
        }
        _activeRomId = id;
        _activeRomType = 'custom';
        _activeRomTitle = cleanTitle;
        _currentRomTitle = cleanTitle;
        await _savePreferences();
        _startAutoSaveTimer();

        // Run game
        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, cleanTitle);
        _isRunning = true;
        _isPaused = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error picking ROM: $e');
    }
    return false;
  }

  Future<bool> loadSavedRom(SavedRomEntry entry) async {
    try {
      if (_isRunning && _activeRomId != null && _activeRomId != entry.id) {
        _bridge.saveState(0, romId: _activeRomId);
      }
      final bytes = await _romStorage.loadRomBytes(entry.id);
      if (bytes != null && bytes.isNotEmpty) {
        _activeRomId = entry.id;
        _activeRomType = 'custom';
        _activeRomTitle = entry.title;
        _currentRomTitle = entry.title;
        _savePreferences();
        _startAutoSaveTimer();

        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, entry.title);
        _isRunning = true;
        _isPaused = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error loading saved ROM: $e');
    }
    return false;
  }

  Future<void> deleteSavedRom(String id) async {
    try {
      await _romStorage.deleteRom(id);
      for (int slot = 0; slot <= 5; slot++) {
        await _romStorage.deleteStateData(id, slot);
      }
      _savedRoms.removeWhere((r) => r.id == id);
      if (_activeRomId == id) {
        _activeRomId = null;
        _activeRomType = null;
        _activeRomTitle = null;
        _currentRomTitle = 'No Game Loaded';
        _isRunning = false;
        _autoSaveTimer?.cancel();
        _bridge.reset();
      }
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting saved ROM: $e');
    }
  }

  void togglePlayPause() {
    if (_isPaused) {
      _bridge.play();
      _isPaused = false;
    } else {
      _bridge.pause();
      _isPaused = true;
    }
    notifyListeners();
  }

  void resetGame() {
    _bridge.reset();
    _isPaused = false;
    notifyListeners();
  }

  void setSpeed(double multiplier) {
    _speed = multiplier;
    _bridge.setSpeed(multiplier);
    notifyListeners();
  }

  void toggleFastForward() {
    if (_speed == 1.0) {
      setSpeed(2.0);
    } else if (_speed == 2.0) {
      setSpeed(4.0);
    } else {
      setSpeed(1.0);
    }
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    if (!_isMuted) {
      _bridge.setVolume(_volume);
    }
    _savePreferences();
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _bridge.setMute(_isMuted);
    notifyListeners();
  }

  void setSkin(GbaSkin newSkin) {
    _skin = newSkin;
    _savePreferences();
    notifyListeners();
  }

  void setFilter(GbaFilter newFilter) {
    _filter = newFilter;
    _bridge.setFilter(newFilter.name);
    _savePreferences();
    notifyListeners();
  }

  void setSelectedSaveSlot(int slot) {
    _selectedSaveSlot = slot;
    _savePreferences();
    notifyListeners();
  }

  void saveCurrentState() {
    _bridge.saveState(_selectedSaveSlot, romId: _activeRomId);
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> loadCurrentState() async {
    if (_activeRomId != null) {
      final savedState = await _romStorage.loadStateData(_activeRomId!, _selectedSaveSlot);
      if (savedState != null && savedState.isNotEmpty) {
        _bridge.loadStateJson(savedState);
        if (_hapticsEnabled) {
          HapticFeedback.mediumImpact();
        }
        return;
      }
    }
    _bridge.loadState(_selectedSaveSlot);
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void toggleHaptics() {
    _hapticsEnabled = !_hapticsEnabled;
    _savePreferences();
    notifyListeners();
  }

  void toggleLandscapeFullscreen() {
    _landscapeFullscreen = !_landscapeFullscreen;
    _savePreferences();
    notifyListeners();
  }

  void setLandscapeFullscreen(bool value) {
    if (_landscapeFullscreen != value) {
      _landscapeFullscreen = value;
      _savePreferences();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
