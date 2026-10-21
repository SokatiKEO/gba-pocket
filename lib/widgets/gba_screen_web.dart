import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../services/gba_controller.dart';

class GbaScreenPlatformWidget extends StatefulWidget {
  final GbaController controller;

  const GbaScreenPlatformWidget({super.key, required this.controller});

  @override
  State<GbaScreenPlatformWidget> createState() => _GbaScreenPlatformWidgetState();
}

class _GbaScreenPlatformWidgetState extends State<GbaScreenPlatformWidget> {
  static bool _registered = false;
  static web.HTMLCanvasElement? _canvasElement;
  static web.HTMLDivElement? _containerElement;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.id = 'gba-container';
      container.style.width = '100%';
      container.style.height = '100%';
      container.style.display = 'flex';
      container.style.alignItems = 'center';
      container.style.justifyContent = 'center';
      container.style.background = '#000000';
      container.style.overflow = 'hidden';

      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.id = 'gba-canvas';
      canvas.width = 240;
      canvas.height = 160;
      canvas.style.width = '100%';
      canvas.style.height = '100%';
      canvas.style.objectFit = 'contain';
      canvas.style.setProperty('image-rendering', 'pixelated');

      container.appendChild(canvas);
      _canvasElement = canvas;
      _containerElement = container;

      ui_web.platformViewRegistry.registerViewFactory('gba-canvas-view', (int viewId) {
        return _containerElement!;
      });
      _registered = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canvasElement != null) {
        widget.controller.initialize(_canvasElement);
      } else {
        widget.controller.initialize(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'gba-canvas-view');
  }
}
