import 'package:flutter/material.dart';

enum GbaButton {
  up,
  down,
  left,
  right,
  a,
  b,
  l,
  r,
  start,
  select;

  String get jsKeyName {
    switch (this) {
      case GbaButton.up: return 'UP';
      case GbaButton.down: return 'DOWN';
      case GbaButton.left: return 'LEFT';
      case GbaButton.right: return 'RIGHT';
      case GbaButton.a: return 'A';
      case GbaButton.b: return 'B';
      case GbaButton.l: return 'L';
      case GbaButton.r: return 'R';
      case GbaButton.start: return 'START';
      case GbaButton.select: return 'SELECT';
    }
  }
}

enum GbaFilter {
  lcd('LCD Pixel Grid', 'Authentic handheld display grid'),
  crisp('Crisp Pixel Art', 'Sharp raw pixels'),
  scanlines('CRT Scanlines', 'Subtle retro arcade scanlines');

  final String label;
  final String description;
  const GbaFilter(this.label, this.description);
}

class GbaSkin {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color bezelColor;
  final Color screenBorderColor;
  final Color dpadColor;
  final Color buttonAColor;
  final Color buttonBColor;
  final Color shoulderColor;
  final Color textColor;
  final bool isTranslucent;

  const GbaSkin({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bezelColor,
    required this.screenBorderColor,
    required this.dpadColor,
    required this.buttonAColor,
    required this.buttonBColor,
    required this.shoulderColor,
    required this.textColor,
    this.isTranslucent = false,
  });

  static const List<GbaSkin> allSkins = [
    GbaSkin(
      id: 'indigo',
      name: 'Classic Indigo',
      primaryColor: Color(0xFF4C4A8C),
      secondaryColor: Color(0xFF373569),
      bezelColor: Color(0xFF1E1C2D),
      screenBorderColor: Color(0xFF6B68AA),
      dpadColor: Color(0xFF232328),
      buttonAColor: Color(0xFF862758),
      buttonBColor: Color(0xFF862758),
      shoulderColor: Color(0xFF7A78AF),
      textColor: Color(0xFFD6D6E8),
    ),
    GbaSkin(
      id: 'glacier',
      name: 'Glacier Blue',
      primaryColor: Color(0xFF338699),
      secondaryColor: Color(0xFF205E6D),
      bezelColor: Color(0xFF112E36),
      screenBorderColor: Color(0xFF56B1C4),
      dpadColor: Color(0xFF1C2D32),
      buttonAColor: Color(0xFF8B2B5C),
      buttonBColor: Color(0xFF8B2B5C),
      shoulderColor: Color(0xFF5AB1C4),
      textColor: Color(0xFFE0F4F7),
      isTranslucent: true,
    ),
    GbaSkin(
      id: 'atomic_purple',
      name: 'Atomic Purple',
      primaryColor: Color(0xFF6A3B8C),
      secondaryColor: Color(0xFF482065),
      bezelColor: Color(0xFF221132),
      screenBorderColor: Color(0xFF9059B8),
      dpadColor: Color(0xFF1E1726),
      buttonAColor: Color(0xFF942866),
      buttonBColor: Color(0xFF942866),
      shoulderColor: Color(0xFF8F58B8),
      textColor: Color(0xFFF3E2FF),
      isTranslucent: true,
    ),
    GbaSkin(
      id: 'arctic_white',
      name: 'Arctic White',
      primaryColor: Color(0xFFEDEDF2),
      secondaryColor: Color(0xFFCACBD4),
      bezelColor: Color(0xFF24252B),
      screenBorderColor: Color(0xFFB0B2BD),
      dpadColor: Color(0xFF3D3E47),
      buttonAColor: Color(0xFFB1293F),
      buttonBColor: Color(0xFFB1293F),
      shoulderColor: Color(0xFFC0C1CE),
      textColor: Color(0xFF2D2E38),
    ),
    GbaSkin(
      id: 'flame_red',
      name: 'Flame Red',
      primaryColor: Color(0xFFC4212D),
      secondaryColor: Color(0xFF8F121C),
      bezelColor: Color(0xFF1F1B1C),
      screenBorderColor: Color(0xFFE64D59),
      dpadColor: Color(0xFF222222),
      buttonAColor: Color(0xFF1E1E22),
      buttonBColor: Color(0xFF1E1E22),
      shoulderColor: Color(0xFFE2414F),
      textColor: Color(0xFFFFD4D7),
    ),
    GbaSkin(
      id: 'stealth_onyx',
      name: 'Stealth Onyx',
      primaryColor: Color(0xFF1E1F24),
      secondaryColor: Color(0xFF121316),
      bezelColor: Color(0xFF0B0C0E),
      screenBorderColor: Color(0xFF3A3B43),
      dpadColor: Color(0xFF28292E),
      buttonAColor: Color(0xFF751F33),
      buttonBColor: Color(0xFF751F33),
      shoulderColor: Color(0xFF373940),
      textColor: Color(0xFFE4E4E8),
    ),
    GbaSkin(
      id: 'zelda_gold',
      name: 'Triforce Gold',
      primaryColor: Color(0xFFC59E37),
      secondaryColor: Color(0xFF8B6C1A),
      bezelColor: Color(0xFF241F13),
      screenBorderColor: Color(0xFFDEC068),
      dpadColor: Color(0xFF2C261B),
      buttonAColor: Color(0xFF1E542E),
      buttonBColor: Color(0xFF1E542E),
      shoulderColor: Color(0xFFD6B553),
      textColor: Color(0xFFFFF3CC),
    ),
  ];
}

class GbaRomInfo {
  final String id;
  final String title;
  final String subtitle;
  final String genre;
  final String year;
  final String assetPath;
  final bool isBuiltIn;

  const GbaRomInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.genre,
    required this.year,
    required this.assetPath,
    this.isBuiltIn = true,
  });

  static const List<GbaRomInfo> builtInRoms = [
    GbaRomInfo(
      id: 'waimanu',
      title: 'Waimanu: Grinding',
      subtitle: 'Disjointed Studio Action Platformer',
      genre: 'Platformer',
      year: '2016',
      assetPath: 'assets/roms/waimanu.gba',
      isBuiltIn: true,
    ),
    GbaRomInfo(
      id: 'yahtzee',
      title: 'Yahtzee Advance',
      subtitle: 'Classic 5-Dice Strategy Game',
      genre: 'Puzzle / Board',
      year: '2005',
      assetPath: 'assets/roms/yahtzee.gba',
      isBuiltIn: true,
    ),
  ];
}

class SavedRomEntry {
  final String id;
  final String title;
  final String fileName;
  final int sizeBytes;
  final DateTime addedAt;

  const SavedRomEntry({
    required this.id,
    required this.title,
    required this.fileName,
    required this.sizeBytes,
    required this.addedAt,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'addedAt': addedAt.toIso8601String(),
  };

  factory SavedRomEntry.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final rawTitle = json['title']?.toString() ?? 'Custom ROM';
    final rawFileName = json['fileName']?.toString() ?? '$rawTitle.gba';
    final rawSize = (json['sizeBytes'] as num?)?.toInt() ?? 0;

    DateTime parsedDate;
    final rawAddedAt = json['addedAt'];
    if (rawAddedAt is String) {
      parsedDate = DateTime.tryParse(rawAddedAt) ?? DateTime.now();
    } else if (rawAddedAt is num) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawAddedAt.toInt());
    } else {
      parsedDate = DateTime.now();
    }

    return SavedRomEntry(
      id: rawId.isEmpty ? 'rom_${DateTime.now().millisecondsSinceEpoch}' : rawId,
      title: rawTitle,
      fileName: rawFileName,
      sizeBytes: rawSize,
      addedAt: parsedDate,
    );
  }
}

