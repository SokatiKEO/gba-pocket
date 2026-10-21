import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/gba_controller.dart';
import '../services/bridge_mobile.dart' as bridge_impl;

class GbaScreenPlatformWidget extends StatefulWidget {
  final GbaController controller;

  const GbaScreenPlatformWidget({super.key, required this.controller});

  @override
  State<GbaScreenPlatformWidget> createState() => _GbaScreenPlatformWidgetState();
}

class _GbaScreenPlatformWidgetState extends State<GbaScreenPlatformWidget> {
  static WebViewController? _controllerSingleton;
  static bool _pageLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (_controllerSingleton != null) {
      if (_pageLoaded) {
        final bridge = widget.controller.bridge;
        if (bridge is bridge_impl.GbaBridgeImpl) {
          bridge.setController(_controllerSingleton!);
        }
        widget.controller.initialize(_controllerSingleton!);
      }
      return;
    }

    try {
      final WebViewController ctrl = WebViewController();
      ctrl
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            final bridge = widget.controller.bridge;
            if (bridge is bridge_impl.GbaBridgeImpl) {
              bridge.handleIncomingMessage(message.message);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _pageLoaded = true;
              final bridge = widget.controller.bridge;
              if (bridge is bridge_impl.GbaBridgeImpl) {
                bridge.setController(ctrl);
              }
              widget.controller.initialize(ctrl);
            },
          ),
        )
        ..loadFlutterAsset('assets/gba_core/emulator.html');

      _controllerSingleton = ctrl;
    } catch (_) {
      _hasError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controllerSingleton == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'GBA Display',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ),
      );
    }
    return WebViewWidget(controller: _controllerSingleton!);
  }
}
