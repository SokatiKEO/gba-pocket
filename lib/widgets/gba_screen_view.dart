import 'package:flutter/material.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';
import 'gba_screen_platform.dart';

class GbaScreenView extends StatelessWidget {
  final GbaController controller;
  final bool isFullscreen;

  const GbaScreenView({
    super.key,
    required this.controller,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final skin = controller.skin;

    if (isFullscreen) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildViewport(context, skin),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: skin.bezelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: skin.screenBorderColor.withValues(alpha: 0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: skin.primaryColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Screen Bezel: Logo & Power LED
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Game Boy Advance Logo
                Row(
                  children: [
                    Text(
                      'GAME BOY ',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Text(
                      'ADVANCE',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFFA855F7), Color(0xFFEC4899)],
                          ).createShader(const Rect.fromLTWH(0, 0, 70, 15)),
                      ),
                    ),
                  ],
                ),

                // Power LED & HUD Badges
                Row(
                  children: [
                    if (controller.isRunning) ...[
                      // FPS Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '${controller.fps} FPS',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Speed Badge
                      if (controller.speed > 1.0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            '${controller.speed.toInt()}x',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],

                    // Power Indicator LED
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !controller.isRunning
                                ? const Color(0xFF333333)
                                : controller.isPaused
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF22C55E),
                            boxShadow: controller.isRunning
                                ? [
                                    BoxShadow(
                                      color: controller.isPaused
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
                                          : const Color(0xFF22C55E).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'POWER',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 3),

          // Main Viewport (240x160 Aspect Ratio: 3:2)
          AspectRatio(
            aspectRatio: 3 / 2,
            child: _buildViewport(context, skin),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport(BuildContext context, GbaSkin skin) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isFullscreen ? 0 : 6),
      child: Stack(
                children: [
                  // Actual Platform View (Web / Mobile Native)
                  Positioned.fill(
                    child: GbaScreenPlatformWidget(controller: controller),
                  ),

                  // Overlay when no ROM is loaded yet
                  if (!controller.isRunning)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF0F1117),
                        child: controller.isRestoring
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF38BDF8),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'RESUMING ${controller.currentRomTitle.toUpperCase()}...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: skin.primaryColor.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: skin.primaryColor.withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.videogame_asset_outlined,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'READY TO PLAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select a game or load your own .gba ROM',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 4,
                                    ),
                                    onPressed: () {
                                      controller.loadBuiltInRom(GbaRomInfo.builtInRoms.first);
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                    label: const Text(
                                      'QUICK START (WAIMANU)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                  // Pause Overlay
                  if (controller.isPaused && controller.isRunning)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pause_circle_filled, color: Colors.white, size: 44),
                              const SizedBox(height: 6),
                              const Text(
                                'PAUSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                ),
                                onPressed: controller.togglePlayPause,
                                child: const Text('RESUME', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Glass Lens Reflection Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.02),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                            stops: const [0.0, 0.25, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
  }
}
