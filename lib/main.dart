import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/root_screen.dart';
import 'services/audius_api.dart';
import 'services/lyrics_service.dart';
import 'theme.dart';
import 'utils/app_messenger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.th06_2324801030055.audio',
    androidNotificationChannelName: 'Phát nhạc',
    androidNotificationOngoing: true,
  );
  runApp(MusicApp(firebaseReady: await _initFirebase()));
}

Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    return false;
  }
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AudiusApi()),
        Provider(create: (_) => LyricsService()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(available: firebaseReady),
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(
          create: (context) => CatalogProvider(context.read<AudiusApi>()),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(available: firebaseReady),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => StatsProvider(
            available: firebaseReady,
            player: context.read<PlayerProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'TH06 Music',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        scaffoldMessengerKey: AppMessenger.key,
        navigatorKey: AppMessenger.navigator,
        home: const RootScreen(),
      ),
    );
  }
}
