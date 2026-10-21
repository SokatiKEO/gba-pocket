import 'package:flutter/material.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';

class GbaQuickMenuModal extends StatelessWidget {
  final GbaController controller;

  const GbaQuickMenuModal({super.key, required this.controller});

  static void show(BuildContext context, GbaController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GbaQuickMenuModal(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16181F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with current game title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARTRIDGE CONTROL',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              controller.currentRomTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),

                  const Divider(color: Colors.white12, height: 24),

                  // Save / Load States Section
                  const Text(
                    'SAVE STATES',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final slot = index + 1;
                      final isSelected = controller.selectedSaveSlot == slot;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.05),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                                width: isSelected ? 1.5 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => controller.setSelectedSaveSlot(slot),
                            child: Text(
                              '#$slot',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            controller.saveCurrentState();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('State saved to Slot #${controller.selectedSaveSlot}!'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            'QUICK SAVE #${controller.selectedSaveSlot}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            controller.loadCurrentState();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Loaded Slot #${controller.selectedSaveSlot}!'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: Text(
                            'QUICK LOAD #${controller.selectedSaveSlot}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: Colors.white12, height: 28),

                  // Game Speed & Controls
                  const Text(
                    'SPEED & PERFORMANCE',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSpeedChip(1.0, '1x Normal'),
                      const SizedBox(width: 8),
                      _buildSpeedChip(2.0, '2x Turbo'),
                      const SizedBox(width: 8),
                      _buildSpeedChip(4.0, '4x Max'),
                    ],
                  ),

                  const Divider(color: Colors.white12, height: 28),

                  // Games Library
                  const Text(
                    'GAME LIBRARY',
                    style: TextStyle(
                      color: Color(0xFFA855F7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Saved Custom ROMs Section (remembered files)
                  if (controller.savedRoms.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MY SAVED ROMS',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${controller.savedRoms.length} stored',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...controller.savedRoms.map((entry) {
                      final isCurrent = controller.currentRomTitle == entry.title;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF38BDF8) : Colors.white10,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.sd_card_outlined, color: Color(0xFF38BDF8), size: 20),
                          ),
                          title: Text(
                            entry.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${entry.fileName} • ${entry.formattedSize}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCurrent ? Colors.white24 : const Color(0xFF38BDF8),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: const Size(54, 28),
                                ),
                                onPressed: () {
                                  controller.loadSavedRom(entry);
                                  Navigator.pop(context);
                                },
                                child: Text(isCurrent ? 'RESTART' : 'PLAY', style: const TextStyle(fontSize: 10)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                                tooltip: 'Remove ROM from library',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () => _confirmRemoveRom(context, controller, entry),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                  ],

                  // Built-in ROMs Section
                  const Text(
                    'BUILT-IN GAMES',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...GbaRomInfo.builtInRoms.map((rom) {
                    final isCurrent = controller.currentRomTitle == rom.title;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFFA855F7).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFFA855F7) : Colors.white10,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.videogame_asset, color: Color(0xFFA855F7)),
                        ),
                        title: Text(
                          rom.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${rom.genre} • ${rom.year}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrent ? Colors.white24 : const Color(0xFFA855F7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          onPressed: () {
                            controller.loadBuiltInRom(rom);
                            Navigator.pop(context);
                          },
                          child: Text(isCurrent ? 'RESTART' : 'PLAY'),
                        ),
                      ),
                    );
                  }),

                  // Add Custom ROM Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final loaded = await controller.pickAndLoadRom();
                      if (loaded && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Center(
                      child: Text(
                        'ADD .GBA ROM FROM STORAGE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 28),

                  // Console Skin Selector
                  const Text(
                    'CONSOLE SKIN',
                    style: TextStyle(
                      color: Color(0xFFEC4899),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: GbaSkin.allSkins.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final s = GbaSkin.allSkins[index];
                        final isSelected = controller.skin.id == s.id;
                        return InkWell(
                          onTap: () => controller.setSkin(s),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? s.primaryColor.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? s.primaryColor : Colors.white12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: s.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 28),

                  // Volume & Haptics
                  Row(
                    children: [
                      IconButton(
                        onPressed: controller.toggleMute,
                        icon: Icon(
                          controller.isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white70,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: controller.volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFF38BDF8),
                          inactiveColor: Colors.white12,
                          onChanged: controller.setVolume,
                        ),
                      ),
                      IconButton(
                        onPressed: controller.toggleHaptics,
                        icon: Icon(
                          controller.hapticsEnabled
                              ? Icons.vibration
                              : Icons.do_not_disturb_on_total_silence,
                          color: controller.hapticsEnabled
                              ? const Color(0xFF10B981)
                              : Colors.white30,
                        ),
                        tooltip: 'Haptic Feedback',
                      ),
                    ],
                  ),

                  const Divider(color: Colors.white12, height: 28),

                  // Display Settings
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Landscape Fullscreen Overlay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Maximizes game display with transparent overlaid controls',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    activeThumbColor: const Color(0xFF38BDF8),
                    value: controller.landscapeFullscreen,
                    onChanged: (val) => controller.setLandscapeFullscreen(val),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedChip(double speedVal, String label) {
    final isSelected = controller.speed == speedVal;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.05),
        side: BorderSide(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.white24,
          width: isSelected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => controller.setSpeed(speedVal),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  static void _confirmRemoveRom(BuildContext context, GbaController controller, SavedRomEntry entry) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Game', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove "${entry.title}" from your saved games library?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              controller.deleteSavedRom(entry.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${entry.title}" from library'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
