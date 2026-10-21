import 'package:flutter/material.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';

class GbaActionButtons extends StatefulWidget {
  final GbaController controller;
  final double buttonSize;

  const GbaActionButtons({
    super.key,
    required this.controller,
    this.buttonSize = 58,
  });

  @override
  State<GbaActionButtons> createState() => _GbaActionButtonsState();
}

class _GbaActionButtonsState extends State<GbaActionButtons> {
  bool _aPressed = false;
  bool _bPressed = false;

  Widget _buildSingleButton({
    required String label,
    required GbaButton button,
    required Color color,
    required bool isPressed,
    required ValueChanged<bool> onStateChange,
  }) {
    return Listener(
      onPointerDown: (_) {
        onStateChange(true);
        widget.controller.pressButton(button);
      },
      onPointerUp: (_) {
        onStateChange(false);
        widget.controller.releaseButton(button);
      },
      onPointerCancel: (_) {
        onStateChange(false);
        widget.controller.releaseButton(button);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.buttonSize,
        height: widget.buttonSize,
        transform: isPressed ? Matrix4.translationValues(0, 3, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPressed
                ? [color.withValues(alpha: 0.8), color]
                : [color.withValues(alpha: 0.95), color.withValues(alpha: 0.75)],
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.controller.skin;

    return SizedBox(
      width: widget.buttonSize * 2.5,
      height: widget.buttonSize * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background capsule plate
          Transform.rotate(
            angle: -0.38, // ~22 degrees tilt
            child: Container(
              width: widget.buttonSize * 2.3,
              height: widget.buttonSize * 1.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.buttonSize),
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ),
          ),

          // B Button (Bottom Left)
          Positioned(
            left: 6,
            bottom: 4,
            child: _buildSingleButton(
              label: 'B',
              button: GbaButton.b,
              color: skin.buttonBColor,
              isPressed: _bPressed,
              onStateChange: (val) => setState(() => _bPressed = val),
            ),
          ),

          // A Button (Top Right)
          Positioned(
            right: 6,
            top: 4,
            child: _buildSingleButton(
              label: 'A',
              button: GbaButton.a,
              color: skin.buttonAColor,
              isPressed: _aPressed,
              onStateChange: (val) => setState(() => _aPressed = val),
            ),
          ),

          // Middle A+B Combo Trigger (Thumb zone between A & B)
          Positioned(
            left: widget.buttonSize * 0.85,
            top: widget.buttonSize * 0.65,
            child: Listener(
              onPointerDown: (_) {
                setState(() {
                  _aPressed = true;
                  _bPressed = true;
                });
                widget.controller.pressButton(GbaButton.a);
                widget.controller.pressButton(GbaButton.b);
              },
              onPointerUp: (_) {
                setState(() {
                  _aPressed = false;
                  _bPressed = false;
                });
                widget.controller.releaseButton(GbaButton.a);
                widget.controller.releaseButton(GbaButton.b);
              },
              onPointerCancel: (_) {
                setState(() {
                  _aPressed = false;
                  _bPressed = false;
                });
                widget.controller.releaseButton(GbaButton.a);
                widget.controller.releaseButton(GbaButton.b);
              },
              child: Container(
                width: widget.buttonSize * 0.75,
                height: widget.buttonSize * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
