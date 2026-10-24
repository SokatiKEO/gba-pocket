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
  bool _wasPausedBeforeBackground = false;
  bool _stateRestoredForCurrentLoad = false;
  bool _isBackgrounded = false;
  bool _explicitlyClearedSavedRoms = false;
  Future<void>? _activeSaveOperation;
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
        } else if (state == AppLifecycleState.resumed) {
          _handleAppResumed();
        }
      },
    );
  }

  void _handleAppBackgrounded() {
    if (_isBackgrounded) return;
    _isBackgrounded = true;

    if (_isRunning) {
      if (_activeRomId != null) {
        _bridge.saveState(0, romId: _activeRomId);
      }
      _wasPausedBeforeBackground = _isPaused;
      _bridge.pause();
      _bridge.setMute(true);
      _isPaused = true;
      _savePreferences();
      notifyListeners();
    } else {
      _savePreferences();
    }
  }

  void _handleAppResumed() {
    _isBackgrounded = false;
    if (_isRunning && !_wasPausedBeforeBackground) {
      _bridge.setMute(_isMuted);
      _bridge.play();
      _isPaused = false;
      notifyListeners();
    }
  }

  Future<void> ensurePreferencesLoaded() async {
    await _preferencesLoadedCompleter.future;
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    // Auto-save every 3 seconds so state is never lost even if the app is closed abruptly
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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

      // 1. Always load disk library first (physical persistent source of truth)
      List<SavedRomEntry> diskRoms = [];
      try {
        diskRoms = await _romStorage.loadLibrary();
      } catch (e) {
        debugPrint('Error loading disk library: $e');
      }
      final Map<String, SavedRomEntry> romMap = {for (final r in diskRoms) r.id: r};

      // 2. Also merge any entries from SharedPreferences
      try {
        final romsJsonList = prefs.getStringList('gba_saved_roms_list');
        if (romsJsonList != null && romsJsonList.isNotEmpty) {
          for (final str in romsJsonList) {
            try {
              final entry = SavedRomEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
              romMap.putIfAbsent(entry.id, () => entry);
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Error loading prefs ROMs: $e');
      }

      _savedRoms = romMap.values.toList();
      if (_savedRoms.isNotEmpty) {
        final list = _savedRoms.map((r) => jsonEncode(r.toJson())).toList();
        await prefs.setStringList('gba_saved_roms_list', list);
        await _romStorage.saveLibrary(_savedRoms);
      }

      // 3. Load active ROM
      _activeRomId = prefs.getString('gba_active_rom_id');
      _activeRomType = prefs.getString('gba_active_rom_type');
      _activeRomTitle = prefs.getString('gba_active_rom_title');

      if (_activeRomId == null) {
        final diskActive = await _romStorage.loadActiveGameMetadata();
        if (diskActive != null) {
          _activeRomId = diskActive['id'] as String?;
          _activeRomType = diskActive['type'] as String?;
          _activeRomTitle = diskActive['title'] as String?;
        }
      }

      if (_activeRomTitle != null && _activeRomTitle!.isNotEmpty) {
        _currentRomTitle = _activeRomTitle!;
        _isRestoring = true;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error in _loadPreferences: $e');
    } finally {
      if (!_preferencesLoadedCompleter.isCompleted) {
        _preferencesLoadedCompleter.complete();
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_activeSaveOperation != null) {
      try {
        await _activeSaveOperation;
      } catch (_) {}
    }
    final saveFuture = _performSavePreferences();
    _activeSaveOperation = saveFuture;
    await saveFuture;
  }

  Future<void> _performSavePreferences() async {
    // Guard against overwriting storage before initial preferences have finished loading
    if (!_preferencesLoadedCompleter.isCompleted) {
      await _preferencesLoadedCompleter.future;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gba_skin_id', _skin.id);
      await prefs.setInt('gba_filter_index', _filter.index);
      await prefs.setDouble('gba_volume', _volume);
      await prefs.setBool('gba_haptics', _hapticsEnabled);
      await prefs.setBool('gba_landscape_fullscreen', _landscapeFullscreen);
      await prefs.setInt('gba_selected_save_slot', _selectedSaveSlot);

      if (_savedRoms.isNotEmpty) {
        final romsJsonList = _savedRoms.map((r) => jsonEncode(r.toJson())).toList();
        await prefs.setStringList('gba_saved_roms_list', romsJsonList);
        await _romStorage.saveLibrary(_savedRoms);
      } else if (_explicitlyClearedSavedRoms) {
        await prefs.remove('gba_saved_roms_list');
        await _romStorage.saveLibrary([]);
      } else {
        // Protect saved ROMs: if memory list was somehow empty and not explicitly cleared by user,
        // recover from SharedPreferences rather than overwriting with []
        final existingList = prefs.getStringList('gba_saved_roms_list');
        if (existingList != null && existingList.isNotEmpty) {
          final recovered = <SavedRomEntry>[];
          for (final str in existingList) {
            try {
              recovered.add(SavedRomEntry.fromJson(jsonDecode(str) as Map<String, dynamic>));
            } catch (_) {}
          }
          if (recovered.isNotEmpty) {
            _savedRoms = recovered;
            notifyListeners();
          }
        }
      }

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

      if (_activeRomId != null && _activeRomType != null) {
        await _romStorage.saveActiveGameMetadata({
          'id': _activeRomId,
          'type': _activeRomType,
          'title': _activeRomTitle,
        });
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
      final matching = _savedRoms.where(
        (r) => r.id == _activeRomId || (_activeRomTitle != null && r.title == _activeRomTitle),
      );
      if (matching.isNotEmpty) {
        await loadSavedRom(matching.first);
      } else if (_savedRoms.isNotEmpty) {
        await loadSavedRom(_savedRoms.first);
      } else if (_activeRomId != null) {
        // Fallback: check if binary exists directly in storage
        final bytes = await _romStorage.loadRomBytes(_activeRomId!);
        if (bytes != null && bytes.isNotEmpty) {
          final recoveredEntry = SavedRomEntry(
            id: _activeRomId!,
            title: _activeRomTitle ?? 'Custom ROM',
            fileName: '${_activeRomTitle ?? 'Custom ROM'}.gba',
            sizeBytes: bytes.length,
            addedAt: DateTime.now(),
          );
          _savedRoms = [recoveredEntry];
          await _romStorage.saveLibrary(_savedRoms);
          await _savePreferences();
          await loadSavedRom(recoveredEntry);
        } else {
          _isRestoring = false;
          notifyListeners();
        }
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
    if (_activeRomId == null || _stateRestoredForCurrentLoad) return;
    try {
      // 1. Check auto-save slot (slot 0) first from persistent disk storage
      String? stateJson = await _romStorage.loadStateData(_activeRomId!, 0);
      // 2. If no auto-save exists, check selected quick save slot (e.g. slot 1)
      if (stateJson == null || stateJson.isEmpty) {
        stateJson = await _romStorage.loadStateData(_activeRomId!, _selectedSaveSlot);
      }
      // 3. Fallback: check any existing save slot (1 to 5)
      if (stateJson == null || stateJson.isEmpty) {
        for (int s = 1; s <= 5; s++) {
          final candidate = await _romStorage.loadStateData(_activeRomId!, s);
          if (candidate != null && candidate.isNotEmpty) {
            stateJson = candidate;
            break;
          }
        }
      }
      if (stateJson != null && stateJson.isNotEmpty) {
        _stateRestoredForCurrentLoad = true;
        await Future.delayed(const Duration(milliseconds: 300));
        _bridge.loadStateJson(stateJson);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        _bridge.loadState(0);
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
    _stateRestoredForCurrentLoad = false;
    setSpeed(1.0);
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
        String cleanId = cleanTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
        if (cleanId.isEmpty) {
          cleanId = 'rom_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          cleanId = 'rom_$cleanId';
        }
        final id = cleanId;

        final entry = SavedRomEntry(
          id: id,
          title: cleanTitle.isEmpty ? 'Custom ROM' : cleanTitle,
          fileName: file.name,
          sizeBytes: bytes.length,
          addedAt: DateTime.now(),
        );

        // Save binary to persistent storage
        await _romStorage.saveRom(entry, bytes);

        // Update in-memory and shared preferences list
        _savedRoms.removeWhere((r) => r.fileName == file.name || r.id == id || r.title == cleanTitle);
        _savedRoms.insert(0, entry);
        _explicitlyClearedSavedRoms = false;

        if (_isRunning && _activeRomId != null && _activeRomId != id) {
          _bridge.saveState(0, romId: _activeRomId);
        }
        _stateRestoredForCurrentLoad = false;
        _activeRomId = id;
        _activeRomType = 'custom';
        _activeRomTitle = cleanTitle;
        _currentRomTitle = cleanTitle;
        await _romStorage.saveLibrary(_savedRoms);
        await _savePreferences();
        _startAutoSaveTimer();

        setSpeed(1.0);
        // Run game
        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, cleanTitle);
        _isRunning = true;
        _isPaused = false;
        notifyListeners();

        // Guaranteed fallback restore
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_stateRestoredForCurrentLoad) {
            _tryRestoreSavedState();
          }
        });
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
        _stateRestoredForCurrentLoad = false;
        _activeRomId = entry.id;
        _activeRomType = 'custom';
        _activeRomTitle = entry.title;
        _currentRomTitle = entry.title;
        _savePreferences();
        _startAutoSaveTimer();

        setSpeed(1.0);
        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, entry.title);
        _isRunning = true;
        _isPaused = false;
        notifyListeners();

        // Guaranteed fallback restore
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_stateRestoredForCurrentLoad) {
            _tryRestoreSavedState();
          }
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error loading saved ROM: $e');
    }
    return false;
  }

  Future<void> restartCurrentGame() async {
    if (_activeRomId == null) return;
    _stateRestoredForCurrentLoad = true;
    _autoSaveTimer?.cancel();
    await _romStorage.deleteStateData(_activeRomId!, 0);

    setSpeed(1.0);
    _isRunning = true;
    _isPaused = false;

    if (_activeRomType == 'builtIn') {
      final rom = GbaRomInfo.builtInRoms.firstWhere(
        (r) => r.id == _activeRomId,
        orElse: () => GbaRomInfo.builtInRoms.first,
      );
      if (kIsWeb) {
        final relativeUrl = rom.id == 'waimanu' ? 'roms/waimanu.gba' : 'roms/yahtzee.gba';
        _bridge.loadRomUrl(relativeUrl, rom.title);
      } else {
        final byteData = await rootBundle.load(rom.assetPath);
        final bytes = byteData.buffer.asUint8List();
        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, rom.title);
      }
    } else if (_activeRomType == 'custom') {
      final bytes = await _romStorage.loadRomBytes(_activeRomId!);
      if (bytes != null && bytes.isNotEmpty) {
        final b64 = base64Encode(bytes);
        _bridge.loadRomBase64(b64, _currentRomTitle);
      }
    }
    _startAutoSaveTimer();
    notifyListeners();
  }

  Future<void> deleteSavedRom(String id) async {
    try {
      await _romStorage.deleteRom(id);
      // Retain state data so user's game progress is not lost if they re-add the ROM
      _savedRoms.removeWhere((r) => r.id == id);
      if (_savedRoms.isEmpty) {
        _explicitlyClearedSavedRoms = true;
      }
      if (_activeRomId == id) {
        _activeRomId = null;
        _activeRomType = null;
        _activeRomTitle = null;
        _currentRomTitle = 'No Game Loaded';
        _isRunning = false;
        _autoSaveTimer?.cancel();
        _bridge.reset();
      }
      await _romStorage.saveLibrary(_savedRoms);
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting saved ROM: $e');
    }
  }

  void togglePlayPause() {
    if (_isPaused) {
      _bridge.setVolume(_isMuted ? 0.0 : _volume);
      _bridge.setMute(_isMuted);
      _bridge.play();
      _isPaused = false;
    } else {
      if (_isRunning && _activeRomId != null) {
        _bridge.saveState(0, romId: _activeRomId);
      }
      _bridge.pause();
      _isPaused = true;
    }
    notifyListeners();
  }

  void resetGame() {
    _bridge.reset();
    _isPaused = false;
    setSpeed(1.0);
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
