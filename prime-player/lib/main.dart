import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'data/services/storage_service.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/playlist_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  await SystemChrome.setPreferredOrientations([
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

class PrimePlayerApp extends ConsumerWidget {
  const PrimePlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly create the player so the first channel tap is instant.
    ref.watch(playerProvider);
    final langCode = ref.watch(localeProvider);
    return MaterialApp(
      title:            'Prime Player',
      debugShowCheckedModeBanner: false,
      theme:            buildAppTheme(),
      locale:           Locale(langCode),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en'), Locale('ar'), Locale('fr'), Locale('es'), Locale('de'),
        Locale('tr'), Locale('it'), Locale('nl'), Locale('pt'), Locale('ru'),
        Locale('zh'), Locale('ja'), Locale('ko'), Locale('fa'), Locale('pl'),
        Locale('ro'), Locale('el'), Locale('uk'), Locale('sv'), Locale('no'),
        Locale('da'), Locale('fi'), Locale('cs'), Locale('hu'), Locale('hr'),
        Locale('bg'), Locale('sr'), Locale('ms'), Locale('id'), Locale('vi'),
        Locale('hi'), Locale('he'), Locale('ur'), Locale('th'), Locale('sk'),
      ],
      home:             const SplashScreen(),
    );
  }
}
