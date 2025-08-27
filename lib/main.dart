import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clarity_flutter/clarity_flutter.dart';

import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/search.dart';
import 'pages/playlist_info.dart';
import 'pages/settings.dart';
import 'pages/local_playlists.dart';

import 'pages/singleplayer_game/single_player.dart';
import 'pages/singleplayer_game/game.dart';
import 'pages/singleplayer_game/result/result_page.dart';
import 'pages/singleplayer_game/offline_game.dart';

import 'pages/multiplayer_game/multi_player.dart';

import '/clarity.dart';
import 'utils/preferences.dart';
import 'theme.dart';
// ignore: unused_import
import 'pages/test.dart';

Future<void> main() async{  
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  if(clarityConfig.projectId.isEmpty) { //在clarity.dart中配置
    runApp(const RhythmRiddle());
  }else{
    runApp(ClarityWidget(app: const RhythmRiddle(), clarityConfig: clarityConfig));
  }
}

class RhythmRiddle extends StatefulWidget {
  const RhythmRiddle({super.key});
  @override
  State<RhythmRiddle> createState() => _RhythmRiddleState();
}

class _RhythmRiddleState extends State<RhythmRiddle> {
  late ThemeProvider _themeProvider;

  Future<void> _initializeTheme() async {
    await _themeProvider.init();
    setState(() {}); // 在加载完成后重新构建界面
  }

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _initializeTheme();
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: [
            const Locale('en'),
            const Locale('zh'),
          ],
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          //home: TestPage(),
          home: LoginPage(),
          routes: {
            '/login': (context) => LoginPage(),
            '/home': (context) => const Home(),
            '/search': (context) => Search(),
            '/PlaylistInfo': (context) => PlaylistInfo(),
            '/SinglePlayer': (context) => SinglePlayer(),
            '/SinglePlayerGame': (context) => SinglePlayerGame(),
            '/SinglePlayerGameResult': (context) => SinglePlayerGameResult(),
            '/OfflineGame': (context) => OfflineGame(),
            '/MultiPlayer': (context) => MultiPlayer(),
            '/settings': (context) => SettingsPage(),
            '/localPlaylists': (context) => LocalPlaylistsPage(),
          },
        ),
      ),
    );
  }
}