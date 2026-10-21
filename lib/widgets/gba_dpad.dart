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
    this.size = 156,
  });

  @override
  State<GbaDpad> createState() => _GbaDpadState();
}

class _GbaDpadState extends State<GbaDpad> {
  final Set<GbaButton> _activeDirections = {};

  void _handlePointerUpdate(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Responsive deadzone in center pivot dish and generous outer reach
    if (distance < widget.size * 0.08 || distance > widget.size * 0.95) {
      _releaseAll();
      return;
    }

    // Angle in degrees (-180 to 180)
    final angle = math.atan2(dy, dx) * 180 / math.pi;

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
    if (_activeDirections.isEmpty) return;
    for (final dir in _activeDirections) {
      widget.controller.releaseButton(dir);
    }
    setState(() {
      _activeDirections.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.controller.skin;
    final dpadColor = skin.dpadColor;

    // Elongated cross arm geometry:
    // armSpan fills 98% of the bounding box.
    // armThickness is 28% of the bounding box.
    // This gives an arm extension of (0.98 - 0.28) / 2 = 0.35 * size on each side,
    // producing a 1.25+ length-to-thickness ratio for long, distinct retro arms.
    final armSpan = widget.size * 0.98;
    final armThickness = widget.size * 0.28;
    final singleArmLength = (armSpan - armThickness) / 2;
    final pivotDiameter = armThickness * 0.88;

    // Physical tactile tilt when pressed
    double tiltX = 0;
    double tiltY = 0;
    if (_activeDirections.contains(GbaButton.left)) tiltX -= 2.0;
    if (_activeDirections.contains(GbaButton.right)) tiltX += 2.0;
    if (_activeDirections.contains(GbaButton.up)) tiltY -= 2.0;
    if (_activeDirections.contains(GbaButton.down)) tiltY += 2.0;

    final isUpPressed = _activeDirections.contains(GbaButton.up);
    final isDownPressed = _activeDirections.contains(GbaButton.down);
    final isLeftPressed = _activeDirections.contains(GbaButton.left);
    final isRightPressed = _activeDirections.contains(GbaButton.right);

    return Listener(
      onPointerDown: (e) => _handlePointerUpdate(e.localPosition),
      onPointerMove: (e) => _handlePointerUpdate(e.localPosition),
      onPointerUp: (_) => _releaseAll(),
      onPointerCancel: (_) => _releaseAll(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sunken bezel recess in handheld casing
            Container(
              width: armSpan + 6,
              height: armSpan + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),

            // Authentic Cross D-Pad Assembly (tilts under finger pressure)
            AnimatedContainer(
              duration: const Duration(milliseconds: 40),
              transform: Matrix4.translationValues(tiltX, tiltY, 0),
              child: SizedBox(
                width: armSpan,
                height: armSpan,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Horizontal Elongated Bar (Left & Right arms)
                    Container(
                      width: armSpan,
                      height: armThickness,
                      decoration: BoxDecoration(
                        color: dpadColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Elongated Bar (Up & Down arms)
                    Container(
                      width: armThickness,
                      height: armSpan,
                      decoration: BoxDecoration(
                        color: dpadColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    // Active Arm Pressed Highlight Overlays
                    if (isUpPressed)
                      Positioned(
                        top: 0,
                        width: armThickness,
                        height: singleArmLength + armThickness / 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (isDownPressed)
                      Positioned(
                        bottom: 0,
                        width: armThickness,
                        height: singleArmLength + armThickness / 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (isLeftPressed)
                      Positioned(
                        left: 0,
                        width: singleArmLength + armThickness / 2,
                        height: armThickness,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (isRightPressed)
                      Positioned(
                        right: 0,
                        width: singleArmLength + armThickness / 2,
                        height: armThickness,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Classic Center Pivot Dish (concave circular indent)
                    Container(
                      width: pivotDiameter,
                      height: pivotDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            dpadColor.withValues(alpha: 0.9),
                            dpadColor,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                    ),

                    // Directional Arrow Indicators (Embossed on elongated arms)
                    Positioned(
                      top: 4,
                      child: Icon(
                        Icons.arrow_drop_up_rounded,
                        color: isUpPressed ? const Color(0xFF38BDF8) : Colors.white38,
                        size: armThickness * 0.72,
                      ),
                    ),

                    Positioned(
                      bottom: 4,
                      child: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: isDownPressed ? const Color(0xFF38BDF8) : Colors.white38,
                        size: armThickness * 0.72,
                      ),
                    ),

                    Positioned(
                      left: 4,
                      child: Icon(
                        Icons.arrow_left_rounded,
                        color: isLeftPressed ? const Color(0xFF38BDF8) : Colors.white38,
                        size: armThickness * 0.72,
                      ),
                    ),

                    Positioned(
                      right: 4,
                      child: Icon(
                        Icons.arrow_right_rounded,
                        color: isRightPressed ? const Color(0xFF38BDF8) : Colors.white38,
                        size: armThickness * 0.72,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
