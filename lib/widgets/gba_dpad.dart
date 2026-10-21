import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';

class GbaDpad extends StatefulWidget {
  final GbaController controller;
  final double size;

  const GbaDpad({
    super.key,
    required this.controller,
    this.size = 148,
  });

  @override
  State<GbaDpad> createState() => _GbaDpadState();
}

class _GbaDpadState extends State<GbaDpad> {
  final Set<GbaButton> _activeDirections = {};
  Offset _knobOffset = Offset.zero;

  void _handlePointerUpdate(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Responsive deadzone and extended outer travel range
    if (distance < widget.size * 0.06 || distance > widget.size * 0.95) {
      _releaseAll();
      return;
    }

    // Angle in degrees (-180 to 180)
    final angle = math.atan2(dy, dx) * 180 / math.pi;

    // Track tactile joystick knob travel
    final maxTravel = widget.size * 0.36;
    final clampedDist = math.min(distance, maxTravel);
    final rad = angle * math.pi / 180;
    _knobOffset = Offset(math.cos(rad) * clampedDist, math.sin(rad) * clampedDist);

    final newDirections = <GbaButton>{};

    // 8-directional mapping (45 degree wedges)
    if (angle >= -22.5 && angle < 22.5) {
      newDirections.add(GbaButton.right);
    } else if (angle >= 22.5 && angle < 67.5) {
      newDirections.add(GbaButton.right);
      newDirections.add(GbaButton.down);
    } else if (angle >= 67.5 && angle < 112.5) {
      newDirections.add(GbaButton.down);
    } else if (angle >= 112.5 && angle < 157.5) {
      newDirections.add(GbaButton.left);
      newDirections.add(GbaButton.down);
    } else if (angle >= 157.5 || angle < -157.5) {
      newDirections.add(GbaButton.left);
    } else if (angle >= -157.5 && angle < -112.5) {
      newDirections.add(GbaButton.left);
      newDirections.add(GbaButton.up);
    } else if (angle >= -112.5 && angle < -67.5) {
      newDirections.add(GbaButton.up);
    } else if (angle >= -67.5 && angle < -22.5) {
      newDirections.add(GbaButton.right);
      newDirections.add(GbaButton.up);
    }

    // Press new, release unpressed
    for (final dir in newDirections) {
      if (!_activeDirections.contains(dir)) {
        widget.controller.pressButton(dir);
      }
    }
    for (final dir in _activeDirections) {
      if (!newDirections.contains(dir)) {
        widget.controller.releaseButton(dir);
      }
    }

    setState(() {
      _activeDirections.clear();
      _activeDirections.addAll(newDirections);
    });
  }

  void _releaseAll() {
    if (_activeDirections.isEmpty && _knobOffset == Offset.zero) return;
    for (final dir in _activeDirections) {
      widget.controller.releaseButton(dir);
    }
    setState(() {
      _activeDirections.clear();
      _knobOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.controller.skin;
    final dpadColor = skin.dpadColor;
    final armSpan = widget.size * 0.96;
    final armThickness = widget.size * 0.32;
    final armLength = widget.size * 0.44;

    return Listener(
      onPointerDown: (e) => _handlePointerUpdate(e.localPosition),
      onPointerMove: (e) => _handlePointerUpdate(e.localPosition),
      onPointerUp: (_) => _releaseAll(),
      onPointerCancel: (_) => _releaseAll(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: armSpan,
            height: armSpan,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Horizontal elongated bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: armSpan,
                  height: armThickness,
                  decoration: BoxDecoration(
                    color: dpadColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // Vertical elongated bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: armThickness,
                  height: armSpan,
                  decoration: BoxDecoration(
                    color: dpadColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // Center pivot depression
                Container(
                  width: widget.size * 0.26,
                  height: widget.size * 0.26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        dpadColor,
                      ],
                    ),
                  ),
                ),

                // Up Arrow
                Positioned(
                  top: 2,
                  child: Icon(
                    Icons.arrow_drop_up,
                    color: _activeDirections.contains(GbaButton.up)
                        ? const Color(0xFF38BDF8)
                        : Colors.white30,
                    size: armLength * 0.68,
                  ),
                ),

                // Down Arrow
                Positioned(
                  bottom: 2,
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: _activeDirections.contains(GbaButton.down)
                        ? const Color(0xFF38BDF8)
                        : Colors.white30,
                    size: armLength * 0.68,
                  ),
                ),

                // Left Arrow
                Positioned(
                  left: 2,
                  child: Icon(
                    Icons.arrow_left,
                    color: _activeDirections.contains(GbaButton.left)
                        ? const Color(0xFF38BDF8)
                        : Colors.white30,
                    size: armLength * 0.68,
                  ),
                ),

                // Right Arrow
                Positioned(
                  right: 2,
                  child: Icon(
                    Icons.arrow_right,
                    color: _activeDirections.contains(GbaButton.right)
                        ? const Color(0xFF38BDF8)
                        : Colors.white30,
                    size: armLength * 0.68,
                  ),
                ),

                // Sliding Move Joystick Indicator Knob
                Transform.translate(
                  offset: _knobOffset,
                  child: Container(
                    width: widget.size * 0.32,
                    height: widget.size * 0.32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: _activeDirections.isNotEmpty ? 0.35 : 0.12),
                          dpadColor,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                      border: Border.all(
                        color: _activeDirections.isNotEmpty
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.7)
                            : Colors.white12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: widget.size * 0.10,
                        height: widget.size * 0.10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _activeDirections.isNotEmpty
                              ? const Color(0xFF38BDF8)
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
