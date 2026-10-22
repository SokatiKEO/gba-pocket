import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';
import '../widgets/gba_action_buttons.dart';
import '../widgets/gba_center_controls.dart';
import '../widgets/gba_dpad.dart';
import '../widgets/gba_quick_menu.dart';
import '../widgets/gba_screen_view.dart';
import '../widgets/gba_shoulder_buttons.dart';

class EmulatorScreen extends StatefulWidget {
  final GbaController controller;

  const EmulatorScreen({super.key, required this.controller});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _screenKey = GlobalKey(debugLabel: 'gba_screen_view_key');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  bool _isSystemUiFullscreen = false;

  void _updateSystemUi(bool isLandscapeFullscreen) {
    if (_isSystemUiFullscreen == isLandscapeFullscreen) return;
    _isSystemUiFullscreen = isLandscapeFullscreen;
    if (isLandscapeFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    if (!isDown && !isUp) return KeyEventResult.ignored;

    GbaButton? btn;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      btn = GbaButton.up;
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      btn = GbaButton.down;
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      btn = GbaButton.left;
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      btn = GbaButton.right;
    } else if (key == LogicalKeyboardKey.keyZ || key == LogicalKeyboardKey.keyJ) {
      btn = GbaButton.b;
    } else if (key == LogicalKeyboardKey.keyX || key == LogicalKeyboardKey.keyK) {
      btn = GbaButton.a;
    } else if (key == LogicalKeyboardKey.keyQ || key == LogicalKeyboardKey.keyU) {
      btn = GbaButton.l;
    } else if (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.keyO) {
      btn = GbaButton.r;
    } else if (key == LogicalKeyboardKey.enter) {
      btn = GbaButton.start;
    } else if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.shiftLeft) {
      btn = GbaButton.select;
    } else if (isDown && key == LogicalKeyboardKey.tab) {
      widget.controller.toggleFastForward();
      return KeyEventResult.handled;
    }

    if (btn != null) {
      if (isDown) {
        widget.controller.pressButton(btn);
      } else {
        widget.controller.releaseButton(btn);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final skin = widget.controller.skin;

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              final isFullscreen = isLandscape && widget.controller.landscapeFullscreen;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateSystemUi(isFullscreen);
              });

              if (isFullscreen) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: _buildLandscapeLayout(context, skin),
                );
              }

              return Scaffold(
                backgroundColor: skin.secondaryColor,
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        skin.primaryColor,
                        skin.secondaryColor,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: isLandscape
                        ? _buildLandscapeLayout(context, skin)
                        : _buildPortraitLayout(context, skin),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, GbaSkin skin) {
    return Column(
      children: [
        // Top L & R Shoulder Buttons
        const SizedBox(height: 6),
        GbaShoulderButtons(controller: widget.controller),
        const SizedBox(height: 6),

        // Screen Bezel & Canvas Viewport
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GbaScreenView(key: _screenKey, controller: widget.controller),
        ),

        const SizedBox(height: 10),

        // Quick Function Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu / Settings Button
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
                  tooltip: 'Settings & ROMs',
                  onPressed: () => GbaQuickMenuModal.show(context, widget.controller),
                ),

                // Fast Forward Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: widget.controller.speed > 1.0
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: widget.controller.toggleFastForward,
                  icon: Icon(
                    Icons.fast_forward_rounded,
                    size: 18,
                    color: widget.controller.speed > 1.0
                        ? const Color(0xFFF59E0B)
                        : Colors.white70,
                  ),
                  label: Text(
                    '${widget.controller.speed.toInt()}x',
                    style: TextStyle(
                      color: widget.controller.speed > 1.0
                          ? const Color(0xFFF59E0B)
                          : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Play / Pause Button
                IconButton(
                  icon: Icon(
                    widget.controller.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  tooltip: 'Pause / Resume',
                  onPressed: widget.controller.togglePlayPause,
                ),

                // Quick Save
                IconButton(
                  icon: const Icon(Icons.save_outlined, color: Colors.white70, size: 20),
                  tooltip: 'Quick Save',
                  onPressed: () {
                    widget.controller.saveCurrentState();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Game state saved!'),
                        duration: Duration(milliseconds: 900),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // Quick Load
                IconButton(
                  icon: const Icon(Icons.restore_outlined, color: Colors.white70, size: 20),
                  tooltip: 'Quick Load',
                  onPressed: () {
                    widget.controller.loadCurrentState();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Game state loaded!'),
                        duration: Duration(milliseconds: 900),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Lower Handheld Controls: D-Pad on Left, A/B on Right
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Virtual D-Pad
              GbaDpad(controller: widget.controller, size: 156),

              // Virtual A/B Buttons
              GbaActionButtons(controller: widget.controller, buttonSize: 56),
            ],
          ),
        ),

        const Spacer(),

        // Select & Start Buttons + Speaker
        GbaCenterControls(controller: widget.controller),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, GbaSkin skin) {
    final isFullscreen = widget.controller.landscapeFullscreen;

    if (isFullscreen) {
      return Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Stack(
              children: [
                // Maximized 3:2 Game Viewport centered across the display
                Positioned.fill(
                  child: Center(
                    child: GbaScreenView(
                      key: _screenKey,
                      controller: widget.controller,
                      isFullscreen: true,
                    ),
                  ),
                ),

                // Semi-transparent controls in the exact same coordinates
                Positioned.fill(
                  child: Row(
                    children: [
                      // Left Column Controls (near left edge, transparent)
                      Expanded(
                        flex: 4,
                        child: Opacity(
                          opacity: 0.40,
                          child: _buildLeftLandscapeControls(skin, isFullscreen: true),
                        ),
                      ),

                      // Center Spacer with floating toolbar at top
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildLandscapeToolbar(context, isFullscreen: true),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                    // Right Column Controls (near right edge, transparent)
                    Expanded(
                      flex: 4,
                      child: Opacity(
                        opacity: 0.40,
                        child: _buildRightLandscapeControls(skin, isFullscreen: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    // Standard Handheld Landscape Layout
    return Row(
      children: [
        // Left Column: L bumper on top, D-Pad below
        Expanded(
          flex: 4,
          child: _buildLeftLandscapeControls(skin, isFullscreen: false),
        ),

        // Center Column: Screen with Bezel + Toolbar below
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: GbaScreenView(
                      key: _screenKey,
                      controller: widget.controller,
                      isFullscreen: false,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildLandscapeToolbar(context, isFullscreen: false),
              ),
            ],
          ),
        ),

        // Right Column: R bumper on top, A/B buttons below
        Expanded(
          flex: 4,
          child: _buildRightLandscapeControls(skin, isFullscreen: false),
        ),
      ],
    );
  }

  Widget _buildLeftLandscapeControls(GbaSkin skin, {bool isFullscreen = false}) {
    if (isFullscreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBumperButton(
                  label: 'L',
                  button: GbaButton.l,
                  isLeft: true,
                ),
                const SizedBox(width: 8),
                _buildPillMini(
                  label: 'SELECT',
                  button: GbaButton.select,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 14),
            child: GbaDpad(
              controller: widget.controller,
              size: 176,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: _buildBumperButton(
            label: 'L',
            button: GbaButton.l,
            isLeft: true,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GbaDpad(
            controller: widget.controller,
            size: 156,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Row(
            children: [
              _buildPillMini(
                label: 'SELECT',
                button: GbaButton.select,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightLandscapeControls(GbaSkin skin, {bool isFullscreen = false}) {
    if (isFullscreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPillMini(
                  label: 'START',
                  button: GbaButton.start,
                ),
                const SizedBox(width: 8),
                _buildBumperButton(
                  label: 'R',
                  button: GbaButton.r,
                  isLeft: false,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 14, bottom: 14),
            child: GbaActionButtons(
              controller: widget.controller,
              buttonSize: 58,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 4),
          child: _buildBumperButton(
            label: 'R',
            button: GbaButton.r,
            isLeft: false,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GbaActionButtons(
            controller: widget.controller,
            buttonSize: 52,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildPillMini(
                label: 'START',
                button: GbaButton.start,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeToolbar(BuildContext context, {required bool isFullscreen}) {
    if (isFullscreen) {
      return Opacity(
        opacity: 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 16),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: 'Settings',
                onPressed: () => GbaQuickMenuModal.show(context, widget.controller),
              ),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: const Size(28, 28),
                ),
                onPressed: widget.controller.toggleFastForward,
                child: Text(
                  '${widget.controller.speed.toInt()}x',
                  style: TextStyle(
                    color: widget.controller.speed > 1.0
                        ? const Color(0xFFF59E0B)
                        : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  widget.controller.isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white70,
                  size: 18,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: 'Pause / Resume',
                onPressed: widget.controller.togglePlayPause,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white70, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: 'Exit Fullscreen',
                onPressed: widget.controller.toggleLandscapeFullscreen,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white70, size: 18),
          tooltip: 'Settings',
          onPressed: () => GbaQuickMenuModal.show(context, widget.controller),
        ),
        const SizedBox(width: 12),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: widget.controller.speed > 1.0
                ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                : Colors.black26,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
          onPressed: widget.controller.toggleFastForward,
          child: Text(
            '${widget.controller.speed.toInt()}x',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            widget.controller.isPaused ? Icons.play_arrow : Icons.pause,
            color: Colors.white70,
            size: 20,
          ),
          tooltip: 'Pause / Resume',
          onPressed: widget.controller.togglePlayPause,
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 20),
          tooltip: 'Fullscreen Mode',
          onPressed: widget.controller.toggleLandscapeFullscreen,
        ),
      ],
    );
  }

  Widget _buildBumperButton({
    required String label,
    required GbaButton button,
    required bool isLeft,
  }) {
    final skin = widget.controller.skin;
    return Listener(
      onPointerDown: (_) => widget.controller.pressButton(button),
      onPointerUp: (_) => widget.controller.releaseButton(button),
      onPointerCancel: (_) => widget.controller.releaseButton(button),
      child: Container(
        width: 72,
        height: 32,
        decoration: BoxDecoration(
          color: skin.shoulderColor,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(16) : const Radius.circular(6),
            topRight: !isLeft ? const Radius.circular(16) : const Radius.circular(6),
            bottomLeft: const Radius.circular(6),
            bottomRight: const Radius.circular(6),
          ),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: skin.textColor,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillMini({required String label, required GbaButton button}) {
    return Listener(
      onPointerDown: (_) => widget.controller.pressButton(button),
      onPointerUp: (_) => widget.controller.releaseButton(button),
      onPointerCancel: (_) => widget.controller.releaseButton(button),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF222226),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
