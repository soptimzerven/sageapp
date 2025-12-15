import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/coop_game.dart';
import 'ui/hud.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/result_overlay.dart';
import 'utils/audio_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both orientations for responsiveness
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide system UI for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const CoopDefenderApp());
}

class CoopDefenderApp extends StatelessWidget {
  const CoopDefenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coop Defender Mini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final CoopGame _game;

  @override
  void initState() {
    super.initState();
    _game = CoopGame();
    // Listen to app lifecycle changes to pause audio when app loses focus
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Pause all audio when app is not active (minimized, switched tabs, etc.)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AudioManager().pauseBackgroundMusic();
      AudioManager().stopAmbientSounds();
    } else if (state == AppLifecycleState.resumed) {
      // Only resume audio if we're in an active game state
      if (_game.gameState == GameState.preparation ||
          _game.gameState == GameState.waveActive) {
        if (!_game.isPaused) {
          AudioManager().resumeBackgroundMusic();
          AudioManager().startAmbientSounds();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<CoopGame>(
        game: _game,
        overlayBuilderMap: {
          'menu': (context, game) => MenuOverlay(game: game),
          'hud': (context, game) => HudOverlay(game: game),
          'pause': (context, game) => PauseOverlay(game: game),
          'result': (context, game) => ResultOverlay(game: game),
        },
        initialActiveOverlays: const ['menu'],
        loadingBuilder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.orange, fontSize: 18),
              ),
            ],
          ),
        ),
        errorBuilder: (context, error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
