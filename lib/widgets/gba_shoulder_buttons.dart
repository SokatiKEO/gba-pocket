import 'package:flutter/material.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';

class GbaShoulderButtons extends StatefulWidget {
  final GbaController controller;

  const GbaShoulderButtons({super.key, required this.controller});

  @override
  State<GbaShoulderButtons> createState() => _GbaShoulderButtonsState();
}

class _GbaShoulderButtonsState extends State<GbaShoulderButtons> {
  bool _lPressed = false;
  bool _rPressed = false;

  Widget _buildBumper({
    required String label,
    required GbaButton button,
    required bool isLeft,
    required bool isPressed,
    required ValueChanged<bool> onStateChange,
  }) {
    final skin = widget.controller.skin;
    final color = skin.shoulderColor;

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
        width: 88,
        height: 38,
        transform: isPressed ? Matrix4.translationValues(0, 2, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isPressed ? color.withValues(alpha: 0.8) : color,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(18) : const Radius.circular(6),
            topRight: !isLeft ? const Radius.circular(18) : const Radius.circular(6),
            bottomLeft: const Radius.circular(8),
            bottomRight: const Radius.circular(8),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
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
                    offset: const Offset(0, 3),
                  ),
                ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPressed
                ? [color.withValues(alpha: 0.7), color]
                : [color.withValues(alpha: 0.95), color.withValues(alpha: 0.8)],
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: skin.textColor.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBumper(
            label: 'L',
            button: GbaButton.l,
            isLeft: true,
            isPressed: _lPressed,
            onStateChange: (v) => setState(() => _lPressed = v),
          ),
          _buildBumper(
            label: 'R',
            button: GbaButton.r,
            isLeft: false,
            isPressed: _rPressed,
            onStateChange: (v) => setState(() => _rPressed = v),
          ),
        ],
      ),
    );
  }
}
