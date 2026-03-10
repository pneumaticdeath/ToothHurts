import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/flavor_config.dart';
import 'ui/screens/main_menu_screen.dart';

/// Default entry point — targets iOS App Store.
void main() {
  _bootstrap(AppFlavor.ios);
}

void _bootstrap(AppFlavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(flavor);

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Immersive full-screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    runApp(const ToothHurtsApp());
  });
}

class ToothHurtsApp extends StatelessWidget {
  const ToothHurtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToothHurts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B8A)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainMenuScreen(),
    );
  }
}
