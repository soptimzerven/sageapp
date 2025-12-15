import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../components/chicken.dart';
import '../components/defense.dart';
import '../components/disturbance.dart';
import '../components/farm_background.dart';
import '../components/items.dart';
import '../utils/audio_manager.dart';
import '../utils/game_effects.dart';
import '../utils/progression_manager.dart';
import 'level_data.dart';

/// Game states for the flow: Menu → Preparation → Wave Active → Result.
enum GameState { menu, preparation, waveActive, result }

/// Main game class for Coop Defender Mini.
class CoopGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
  CoopGame()
    : super(
        camera: CameraComponent.withFixedResolution(width: 1280, height: 720),
      );

  /// Fixed world size for the game (used for positioning game elements).
  static const double worldWidth = 1280;
  static const double worldHeight = 720;

  /// Get the world bounds as a Vector2 for convenience.
  Vector2 get worldSize => Vector2(worldWidth, worldHeight);

  /// The poultry area where chickens must stay (centered in playable space).
  /// This is the protected zone that enemies try to reach.
  /// Accounts for top HUD (~50px) and bottom toolbar (~90px) to center properly.
  Rect get poultryArea {
    const areaWidth = 420.0;
    const areaHeight = 280.0;
    // Account for UI: top HUD ~50px, bottom toolbar ~90px
    const topUIHeight = 50.0;
    const bottomUIHeight = 90.0;
    // Calculate center of the playable area (between top HUD and bottom toolbar)
    final playableTop = topUIHeight;
    final playableBottom = worldHeight - bottomUIHeight;
    final playableHeight = playableBottom - playableTop;
    final centerX = worldWidth / 2;
    final centerY = playableTop + (playableHeight / 2);
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: areaWidth,
      height: areaHeight,
    );
  }

  /// Defense being dragged (for drag-and-drop placement).
  Defense? _draggingDefense;
  Defense? get draggingDefense => _draggingDefense;

  /// Whether we're currently in drag mode.
  bool get isDraggingDefense => _draggingDefense != null;

  /// Current game state.
  GameState _gameState = GameState.menu;
  GameState get gameState => _gameState;

  /// Whether the game is currently paused.
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  /// Current level number (1-indexed).
  int _currentLevel = 1;
  int get currentLevel => _currentLevel;

  /// Current level data.
  Level get levelData => LevelData.getLevel(_currentLevel);

  /// Available coins for placing defenses.
  int _coins = 0;
  int get coins => _coins;

  /// Currently selected defense type for placement.
  DefenseType? _selectedDefenseType;
  DefenseType? get selectedDefenseType => _selectedDefenseType;

  /// List of chickens in the game.
  final List<Chicken> chickens = [];

  /// List of placed defenses.
  final List<Defense> defenses = [];

  /// List of active disturbances.
  final List<Disturbance> disturbances = [];

  /// List of items (eggs, feed).
  final List<Item> items = [];

  /// Wave spawners.
  final List<DisturbanceSpawner> _spawners = [];

  /// Current environmental modifier for the level.
  String? get currentModifier => levelData.modifier;

  /// Available defense types for current level.
  List<DefenseType> get availableDefenseTypes {
    return levelData.availableTools
        .map((tool) => DefenseFactory.fromString(tool))
        .whereType<DefenseType>()
        .toList();
  }

  /// Tap handler component for placing defenses.
  late final _TapHandlerComponent _tapHandler;

  /// Wave timer.
  double _waveTimer = 0;
  double _waveDuration = 0;

  /// Calculate safety score based on chickens not scared during wave.
  double get safetyScore {
    if (chickens.isEmpty) return 100;
    final notScared = chickens.where((c) => !c.wasScaredDuringWave).length;
    return (notScared / chickens.length) * 100;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Position camera so world coordinates go from (0,0) to (worldWidth, worldHeight)
    // The fixed resolution camera is centered at (0,0) by default, so we need to move it
    camera.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);

    // Add tap handler
    _tapHandler = _TapHandlerComponent();
    add(_tapHandler);

    // Preload audio (but don't play yet - only play during active gameplay)
    await AudioManager().preloadAll();

    // Show menu (no music on menu)
    _setGameState(GameState.menu);
  }

  /// Set game state and update overlays accordingly.
  void _setGameState(GameState newState) {
    _gameState = newState;

    // Clear all overlays first
    overlays.remove('menu');
    overlays.remove('hud');
    overlays.remove('result');

    // Manage audio and overlays based on game state
    switch (newState) {
      case GameState.menu:
        overlays.add('menu');
        // Stop all sounds when on menu
        AudioManager().stopBackgroundMusic();
        AudioManager().stopAmbientSounds();
      case GameState.preparation:
        overlays.add('hud');
        // Start music and ambient sounds during preparation
        AudioManager().playBackgroundMusic();
        AudioManager().startAmbientSounds();
      case GameState.waveActive:
        overlays.add('hud');
        // Keep music and ambient sounds running during wave
        AudioManager().playBackgroundMusic();
      case GameState.result:
        overlays.add('result');
        // Stop ambient sounds but keep music briefly for result screen
        AudioManager().stopAmbientSounds();
        AudioManager().stopBackgroundMusic();
    }

    notifyListeners();
  }

  /// Start the game from the menu.
  void startGame() {
    _loadLevel();
    _setGameState(GameState.preparation);
  }

  /// Load the current level.
  void _loadLevel() {
    // Clear existing components
    _clearGameComponents();

    // Add background
    world.add(FarmBackground());

    // Set coins from level budget
    _coins = levelData.budget;

    // Spawn chickens
    _spawnChickens();

    notifyListeners();
  }

  /// Clear all game components.
  void _clearGameComponents() {
    for (final chicken in chickens) {
      chicken.removeFromParent();
    }
    chickens.clear();

    for (final defense in defenses) {
      defense.removeFromParent();
    }
    defenses.clear();

    for (final disturbance in disturbances) {
      disturbance.removeFromParent();
    }
    disturbances.clear();

    for (final item in items) {
      item.removeFromParent();
    }
    items.clear();

    for (final spawner in _spawners) {
      spawner.removeFromParent();
    }
    _spawners.clear();

    // Remove background
    world.children.whereType<FarmBackground>().forEach((bg) {
      bg.removeFromParent();
    });
  }

  /// Spawn chickens for the level inside the poultry area.
  /// Uses a circular distribution centered precisely in the poultry zone.
  void _spawnChickens() {
    final random = Random();
    final area = poultryArea;
    final chickenCount = levelData.chickens;

    // Calculate the true center of the poultry area
    final centerX = area.center.dx;
    final centerY = area.center.dy;

    // Calculate safe spawn radius - keep chickens well inside boundary
    // Use 35% of the smaller dimension to ensure proper padding
    final maxRadius =
        (area.width < area.height ? area.width : area.height) * 0.35;

    // For small numbers (1-3), place in a tight cluster at center
    if (chickenCount <= 3) {
      for (int i = 0; i < chickenCount; i++) {
        // Use very small offsets from center
        final angle = (i / chickenCount) * 2 * pi + (random.nextDouble() * 0.3);
        final radius = 20.0 + random.nextDouble() * 30;
        final x = centerX + cos(angle) * radius;
        final y = centerY + sin(angle) * radius;

        final chicken = Chicken(position: Vector2(x, y));
        world.add(chicken);
        chickens.add(chicken);
      }
      return;
    }

    // For larger numbers, use concentric rings centered on the area
    // This ensures balanced, visually pleasing distribution
    final rings = chickenCount <= 6 ? 2 : 3;
    int placedCount = 0;

    for (int ring = 0; ring < rings && placedCount < chickenCount; ring++) {
      // Calculate radius for this ring (inner rings have smaller radius)
      final ringProgress = (ring + 1) / rings;
      final ringRadius = maxRadius * ringProgress * 0.8;

      // Calculate how many chickens go in this ring
      final chickensInRing = ring == 0
          ? (chickenCount <= 6 ? 2 : 3) // Inner ring: 2-3 chickens
          : (chickenCount - placedCount) ~/
                (rings - ring); // Distribute remaining

      final actualChickensInRing = (chickensInRing > 0) ? chickensInRing : 1;

      for (
        int i = 0;
        i < actualChickensInRing && placedCount < chickenCount;
        i++
      ) {
        // Distribute evenly around the ring with slight randomization
        final baseAngle = (i / actualChickensInRing) * 2 * pi;
        final angleJitter =
            (random.nextDouble() - 0.5) * 0.4; // Small angle variation
        final angle =
            baseAngle + angleJitter + (ring * 0.5); // Offset each ring

        // Add slight radius variation
        final radiusJitter = (random.nextDouble() - 0.5) * 15;
        final actualRadius = ringRadius + radiusJitter;

        final x = centerX + cos(angle) * actualRadius;
        final y = centerY + sin(angle) * actualRadius;

        final chicken = Chicken(position: Vector2(x, y));
        world.add(chicken);
        chickens.add(chicken);
        placedCount++;
      }
    }
  }

  /// Select a defense type for placement.
  void selectDefenseType(DefenseType type) {
    if (_gameState != GameState.preparation) return;
    if (_coins < DefenseFactory.getCost(type)) return;

    _selectedDefenseType = type;
    notifyListeners();
  }

  /// Start the wave.
  void startWave() {
    if (_gameState != GameState.preparation) return;

    _selectedDefenseType = null;
    _setGameState(GameState.waveActive);

    // Reset chicken states
    for (final chicken in chickens) {
      chicken.resetForNewWave();
    }

    // Create spawners for each wave
    _waveDuration = 0;
    for (final wave in levelData.waves) {
      final spawner = DisturbanceSpawner(
        foxCount: wave.foxCount,
        ratCount: wave.ratCount,
        germCount: wave.germCount,
        birdCount: wave.birdCount,
        spawnDuration: wave.spawnDuration,
        startDelay: wave.startDelay,
      );
      world.add(spawner);
      _spawners.add(spawner);

      // Calculate total wave duration
      final waveTotalTime =
          wave.startDelay + wave.spawnDuration + 5; // +5 for cleanup
      if (waveTotalTime > _waveDuration) {
        _waveDuration = waveTotalTime;
      }
    }

    _waveTimer = 0;
  }

  /// Return to menu.
  void returnToMenu() {
    _clearGameComponents();
    _currentLevel = 1;
    _setGameState(GameState.menu);
  }

  /// Retry current level.
  void retryLevel() {
    _loadLevel();
    _setGameState(GameState.preparation);
  }

  /// Advance to next level.
  void nextLevel() {
    if (_currentLevel < LevelData.totalLevels) {
      _currentLevel++;
    }
    _loadLevel();
    _setGameState(GameState.preparation);
  }

  /// Pause the game.
  void pauseGame() {
    if (_gameState == GameState.waveActive ||
        _gameState == GameState.preparation) {
      _isPaused = true;
      pauseEngine();
      overlays.add('pause');
      // Pause audio when game is paused
      AudioManager().pauseBackgroundMusic();
      AudioManager().stopAmbientSounds();
      notifyListeners();
    }
  }

  /// Resume the game.
  void resumeGame() {
    if (_isPaused) {
      _isPaused = false;
      resumeEngine();
      overlays.remove('pause');
      // Resume audio when game is resumed
      AudioManager().resumeBackgroundMusic();
      AudioManager().startAmbientSounds();
      notifyListeners();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update game logic if paused
    if (_isPaused) return;

    if (_gameState == GameState.waveActive) {
      _updateWave(dt);
    }

    // Clean up removed disturbances
    disturbances.removeWhere((d) => d.shouldRemove || d.parent == null);

    // Clean up removed items
    items.removeWhere((i) => i.parent == null);
  }

  void _updateWave(double dt) {
    _waveTimer += dt;

    // Check if wave is complete
    final allSpawnersComplete = _spawners.every((s) => s.isComplete);
    final allDisturbancesGone =
        disturbances.isEmpty ||
        disturbances.every((d) => d.shouldRemove || d.isFleeing);

    if (allSpawnersComplete && allDisturbancesGone && _waveTimer > 3) {
      _endWave();
    }

    // Also end wave after timeout
    if (_waveTimer >= _waveDuration + 10) {
      _endWave();
    }
  }

  /// Coins earned in the last completed level.
  int _lastLevelReward = 0;
  int get lastLevelReward => _lastLevelReward;

  void _endWave() {
    // Remove all remaining disturbances
    for (final disturbance in disturbances) {
      disturbance.removeFromParent();
    }
    disturbances.clear();

    // Remove spawners
    for (final spawner in _spawners) {
      spawner.removeFromParent();
    }
    _spawners.clear();

    // Play appropriate sound and apply effects
    if (safetyScore >= 90) {
      AudioManager().playSuccessSound();

      // Award coins for completing the level
      _lastLevelReward = ProgressionManager().calculateLevelReward(
        _currentLevel,
        safetyScore,
      );
      ProgressionManager().awardLevelReward(_currentLevel, safetyScore);

      // Add celebration particle effects
      world.add(SuccessParticles(screenSize: worldSize));

      // Add star bursts around the screen
      for (int i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: 200 * i), () {
          if (isMounted) {
            final random = Random();
            world.add(
              StarBurstParticles(
                position: Vector2(
                  100 + random.nextDouble() * (worldWidth - 200),
                  150 + random.nextDouble() * (worldHeight - 400),
                ),
              ),
            );
          }
        });
      }
    } else {
      AudioManager().playFailSound();
      _lastLevelReward = 0;

      // Screen shake effect on fail
      camera.shake(intensity: 12.0, shakes: 8);
    }

    _setGameState(GameState.result);
  }

  /// Start dragging a defense from the toolbar.
  void startDraggingDefense(DefenseType type, Vector2 position) {
    if (_gameState != GameState.preparation) return;

    final cost = DefenseFactory.getCost(type);
    if (_coins < cost) return;

    // Create the defense and add it to the world
    _draggingDefense = DefenseFactory.create(type, position);
    _draggingDefense!.isDragging = true;
    _draggingDefense!.opacity = 0.7; // Semi-transparent while dragging
    world.add(_draggingDefense!);

    _selectedDefenseType = type;
    notifyListeners();
  }

  /// Update the position of the defense being dragged.
  void updateDraggingDefense(Vector2 position) {
    if (_draggingDefense == null) return;
    _draggingDefense!.position = position;
  }

  /// Cancel the current drag operation.
  void cancelDraggingDefense() {
    if (_draggingDefense != null) {
      _draggingDefense!.removeFromParent();
      _draggingDefense = null;
      _selectedDefenseType = null;
      notifyListeners();
    }
  }

  /// Complete the drag and place the defense if valid.
  void completeDraggingDefense(Vector2 position) {
    if (_draggingDefense == null || _selectedDefenseType == null) return;

    // Check if placement is valid (outside poultry area, within game bounds)
    if (isValidPlacementPosition(position)) {
      // Finalize position
      _draggingDefense!.position = position;
      _draggingDefense!.isDragging = false;
      _draggingDefense!.opacity = 1.0;

      // Add to defenses list
      defenses.add(_draggingDefense!);

      // Mark as placed and trigger placement
      _onDefensePlaced(_draggingDefense!);

      // Deduct cost
      _coins -= DefenseFactory.getCost(_selectedDefenseType!);
    } else {
      // Invalid placement - remove the defense
      _draggingDefense!.removeFromParent();
    }

    _draggingDefense = null;
    _selectedDefenseType = null;
    notifyListeners();
  }

  /// Check if a position is valid for defense placement.
  /// Defenses can be placed anywhere within the game bounds.
  bool isValidPlacementPosition(Vector2 position) {
    // Must be within game bounds (with padding for UI elements)
    if (position.y < 60 || position.y > worldHeight - 80) return false;
    if (position.x < 30 || position.x > worldWidth - 30) return false;

    return true;
  }

  /// Handle tap at position for placing defenses (fallback for simple tap).
  void handleTapAt(Vector2 position) {
    if (_gameState != GameState.preparation) return;
    if (_selectedDefenseType == null) return;

    final cost = DefenseFactory.getCost(_selectedDefenseType!);
    if (_coins < cost) return;

    // Check if placement is valid
    if (!isValidPlacementPosition(position)) return;

    final defense = DefenseFactory.create(_selectedDefenseType!, position);
    world.add(defense);
    defenses.add(defense);

    // Mark as placed and trigger placement
    _onDefensePlaced(defense);

    // Deduct cost
    _coins -= cost;

    // Clear selection
    _selectedDefenseType = null;

    notifyListeners();
  }

  /// Handle defense placement callback.
  void _onDefensePlaced(Defense defense) {
    defense.onPlaced();
  }
}

/// Component to handle tap events for the game.
class _TapHandlerComponent extends Component
    with TapCallbacks, HasGameReference<CoopGame> {
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    game.handleTapAt(event.canvasPosition);
  }
}
