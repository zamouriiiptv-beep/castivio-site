import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'data/services/storage_service.dart';
import 'presentation/providers/playlist_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const PrimePlayerApp(),
    ),
  );
}

class PrimePlayerApp extends StatelessWidget {
  const PrimePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:            'Prime Player',
      debugShowCheckedModeBanner: false,
      theme:            buildAppTheme(),
      home:             const SplashScreen(),
    );
  }
}
