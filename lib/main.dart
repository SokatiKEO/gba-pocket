import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/emulator_screen.dart';
import 'services/gba_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge transparent system bars for immersive mobile experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Allow both portrait and landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final controller = GbaController();

  runApp(GbaEmulatorApp(controller: controller));
}

class GbaEmulatorApp extends StatelessWidget {
  final GbaController controller;

  const GbaEmulatorApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GBA Pocket',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF111216),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFA855F7),
          surface: Color(0xFF181A20),
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: EmulatorScreen(controller: controller),
    );
  }
}
