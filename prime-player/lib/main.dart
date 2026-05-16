import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'data/services/storage_service.dart';
import 'presentation/providers/playlist_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Pre-initialize player at startup — libmpv is warm before any channel tap
  final player = Player(
    configuration: PlayerConfiguration(
      bufferSize: 32 * 1024 * 1024,
      logLevel:   MPVLogLevel.error,
    ),
  );
  final controller = VideoController(player);

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
        playerProvider.overrideWith(() => PlayerNotifier(player, controller)),
      ],
      child: const PrimePlayerApp(),
    ),
  );
}

class PrimePlayerApp extends ConsumerWidget {
  const PrimePlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize the player provider so libmpv is ready before first tap
    ref.watch(playerProvider);
    return MaterialApp(
      title:            'Prime Player',
      debugShowCheckedModeBanner: false,
      theme:            buildAppTheme(),
      home:             const SplashScreen(),
    );
  }
}
