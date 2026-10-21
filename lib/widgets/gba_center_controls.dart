import 'package:flutter/material.dart';
import '../models/gba_types.dart';
import '../services/gba_controller.dart';

class GbaCenterControls extends StatefulWidget {
  final GbaController controller;

  const GbaCenterControls({super.key, required this.controller});

  @override
  State<GbaCenterControls> createState() => _GbaCenterControlsState();
}

class _GbaCenterControlsState extends State<GbaCenterControls> {
  bool _startPressed = false;
  bool _selectPressed = false;

  Widget _buildPillButton({
    required String label,
    required GbaButton button,
    required bool isPressed,
    required ValueChanged<bool> onStateChange,
  }) {
    final skin = widget.controller.skin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
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
          child: Transform.rotate(
            angle: -0.42, // Angled rubber pill button
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              width: 38,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isPressed ? const Color(0xFF222226) : const Color(0xFF3E3F47),
                boxShadow: isPressed
                    ? [
                        const BoxShadow(
                          color: Colors.black45,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: skin.textColor.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerGrille() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final widths = [16.0, 22.0, 22.0, 16.0];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Container(
            width: widths[index],
            height: 3.5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Select Button
          _buildPillButton(
            label: 'SELECT',
            button: GbaButton.select,
            isPressed: _selectPressed,
            onStateChange: (v) => setState(() => _selectPressed = v),
          ),

          // Center Speaker Grille
          _buildSpeakerGrille(),

          // Start Button
          _buildPillButton(
            label: 'START',
            button: GbaButton.start,
            isPressed: _startPressed,
            onStateChange: (v) => setState(() => _startPressed = v),
          ),
        ],
      ),
    );
  }
}
