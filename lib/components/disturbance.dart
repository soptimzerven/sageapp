import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../game/coop_game.dart';
import '../utils/audio_manager.dart';
import 'chicken.dart';
import 'defense.dart';
import 'items.dart';

/// Base class for all disturbances (threats to chickens).
abstract class Disturbance extends SpriteComponent
    with HasGameReference<CoopGame>, CollisionCallbacks, TapCallbacks {
  Disturbance({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);

  /// Movement speed of the disturbance.
  double speed = 80;

  /// Whether this disturbance is currently fleeing.
  bool isFleeing = false;

  /// Whether this disturbance is trying to go around a defense.
  bool isAvoidingDefense = false;

  /// Direction to flee when repelled.
  Vector2 fleeDirection = Vector2.zero();

  /// Direction to go around a defense.
  Vector2 avoidDirection = Vector2.zero();

  /// Timer for fleeing behavior.
  double fleeTimer = 0;
  final double fleeDuration = 2.0;

  /// Timer for avoiding behavior.
  double avoidTimer = 0;
  final double avoidDuration = 1.5;

  /// Whether this disturbance should be removed.
  bool shouldRemove = false;

  /// Range at which chickens become alert.
  double alertRange = 150;

  /// Strength of this disturbance (determines if it can break through weak defenses).
  int strength = 1;

  /// Number of taps required to push this enemy away.
  int get tapsRequired => strength * 5;

  /// Current tap count from player.
  int _tapCount = 0;

  /// Visual feedback for tap progress.
  _TapProgressIndicator? _tapIndicator;

  /// Handle player tapping on the disturbance to push it away.
  @override
  void onTapDown(TapDownEvent event) {
    if (isFleeing || shouldRemove) return;

    _tapCount++;

    // Show tap feedback
    _showTapFeedback();

    // Play a light sound
    AudioManager().playBellSound();

    // Check if enough taps to push away
    if (_tapCount >= tapsRequired) {
      // Push enemy away from center of screen
      final centerOfScreen = Vector2(
        CoopGame.worldWidth / 2,
        CoopGame.worldHeight / 2,
      );
      final awayDirection = (position - centerOfScreen).normalized();
      flee(awayDirection);
      _tapCount = 0;
      _hideTapIndicator();
    }
  }

  void _showTapFeedback() {
    // Create or update tap progress indicator
    if (_tapIndicator == null) {
      _tapIndicator = _TapProgressIndicator();
      add(_tapIndicator!);
    }
    _tapIndicator!.updateProgress(_tapCount / tapsRequired);

    // Visual shake effect
    final random = Random();
    position += Vector2(
      (random.nextDouble() - 0.5) * 8,
      (random.nextDouble() - 0.5) * 8,
    );
  }

  void _hideTapIndicator() {
    _tapIndicator?.removeFromParent();
    _tapIndicator = null;
  }

  /// Find the nearest chicken in the game.
  Chicken? findNearestChicken() {
    Chicken? nearest;
    double minDistance = double.infinity;

    for (final chicken in game.chickens) {
      final distance = position.distanceTo(chicken.position);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = chicken;
      }
    }
    return nearest;
  }

  /// Alert chickens that are within range.
  void alertNearbyChickens() {
    for (final chicken in game.chickens) {
      final distance = position.distanceTo(chicken.position);
      if (distance < alertRange && chicken.state == ChickenState.idle) {
        chicken.onDisturbanceNearby();
      }
    }
  }

  /// Start fleeing in the given direction.
  void flee(Vector2 direction) {
    isFleeing = true;
    isAvoidingDefense = false;
    fleeDirection = direction.normalized();
    fleeTimer = 0;
  }

  /// Start trying to go around a defense.
  void avoidDefense(Vector2 defensePosition) {
    if (isFleeing) return; // Don't override flee

    isAvoidingDefense = true;
    avoidTimer = 0;

    // Calculate perpendicular direction to go around
    final toDefense = defensePosition - position;
    // Choose left or right based on current position
    final perpendicular = Vector2(-toDefense.y, toDefense.x).normalized();

    // Add some randomness to avoid getting stuck
    final random = Random();
    if (random.nextBool()) {
      avoidDirection = perpendicular;
    } else {
      avoidDirection = -perpendicular;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFleeing) {
      _handleFleeing(dt);
    } else if (isAvoidingDefense) {
      _handleAvoiding(dt);
    }

    // Check if out of bounds
    if (_isOutOfBounds()) {
      shouldRemove = true;
      removeFromParent();
    }
  }

  void _handleFleeing(double dt) {
    fleeTimer += dt;
    position += fleeDirection * speed * 1.5 * dt; // Flee faster

    if (fleeTimer >= fleeDuration) {
      shouldRemove = true;
      removeFromParent();
    }
  }

  void _handleAvoiding(double dt) {
    avoidTimer += dt;
    position += avoidDirection * speed * 0.8 * dt;

    if (avoidTimer >= avoidDuration) {
      isAvoidingDefense = false;
      avoidTimer = 0;
    }
  }

  bool _isOutOfBounds() {
    final margin = 100.0;
    return position.x < -margin ||
        position.x > game.worldSize.x + margin ||
        position.y < -margin ||
        position.y > game.worldSize.y + margin;
  }
}

/// Enum for disturbance types.
enum DisturbanceType { fox, rat, germBubble, birdShadow }

/// Visual indicator showing tap progress on an enemy.
class _TapProgressIndicator extends PositionComponent {
  _TapProgressIndicator()
    : super(position: Vector2(0, -40), anchor: Anchor.center);

  double _progress = 0;

  void updateProgress(double progress) {
    _progress = progress.clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (_progress <= 0) return;

    // Background bar
    final bgPaint = Paint()
      ..color = const Color(0x80000000)
      ..style = PaintingStyle.fill;

    const barWidth = 40.0;
    const barHeight = 6.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(3),
      ),
      bgPaint,
    );

    // Progress bar
    final progressPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFFAA00),
        const Color(0xFFFF4400),
        _progress,
      )!
      ..style = PaintingStyle.fill;

    final progressWidth = barWidth * _progress;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, -barHeight / 2, progressWidth, barHeight),
        const Radius.circular(3),
      ),
      progressPaint,
    );

    // Draw a pulsing indicator dot when in progress
    if (_progress > 0 && _progress < 1) {
      final dotPaint = Paint()
        ..color = const Color(0xFFFF6600)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(barWidth / 2 + 10, 0), 6, dotPaint);
      // Inner highlight
      final highlightPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(barWidth / 2 + 9, -1), 2, highlightPaint);
    }
  }
}

/// Fox disturbance - moves toward chickens, blocked by Fence, chased by Dog.
class Fox extends Disturbance {
  Fox({required super.position}) : super(size: Vector2(56, 56)) {
    speed = 55;
    strength = 2; // Strong - requires 10 taps to push away
  }

  /// How many times this fox has hit a fence.
  int _fenceHits = 0;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('disturbance_fox.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFleeing || shouldRemove) return;

    // If avoiding, don't move toward target
    if (isAvoidingDefense) return;

    // Move toward nearest chicken
    final target = findNearestChicken();
    if (target != null) {
      final direction = (target.position - position).normalized();
      position += direction * speed * dt;
    }

    // Alert nearby chickens
    alertNearbyChickens();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Chicken && !isFleeing) {
      // Scare the chicken
      other.onDisturbanceContact();
    } else if (other is Fence && !isFleeing) {
      _fenceHits++;

      // After multiple hits, try to go around instead of just stopping
      if (_fenceHits >= 3) {
        // Give up and flee after too many attempts
        final awayDirection = (position - other.position).normalized();
        flee(awayDirection);
      } else {
        // Try to go around the fence
        avoidDefense(other.position);
      }
    } else if (other is Dog && !isFleeing) {
      // Dogs always make foxes flee
      final awayDirection = (position - other.position).normalized();
      flee(awayDirection);
    }
  }
}

/// Rat disturbance - smaller, steals eggs/feed, can squeeze through fences.
class Rat extends Disturbance {
  Rat({required super.position}) : super(size: Vector2(36, 36)) {
    speed = 70; // Fast
    alertRange = 80; // Smaller alert range
    strength = 1; // Weak - requires 5 taps to push away
  }

  /// Current target (egg or feed).
  PositionComponent? _target;

  /// Whether this rat has slipped through a fence.
  bool _slippedThrough = false;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('disturbance_rat.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFleeing || shouldRemove) return;
    if (isAvoidingDefense) return;

    // Prioritize targeting items (eggs/feed), then chickens
    _findTarget();

    if (_target != null) {
      final direction = (_target!.position - position).normalized();
      position += direction * speed * dt;
    }

    // Alert nearby chickens
    alertNearbyChickens();
  }

  void _findTarget() {
    // First try to find eggs or feed
    double minDistance = double.infinity;
    _target = null;

    for (final item in game.items) {
      final distance = position.distanceTo(item.position);
      if (distance < minDistance) {
        minDistance = distance;
        _target = item;
      }
    }

    // If no items, target chickens
    _target ??= findNearestChicken();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Egg && !isFleeing) {
      // Steal the egg
      other.removeFromParent();
      game.items.remove(other);
    } else if (other is Feed && !isFleeing) {
      // Steal the feed
      other.removeFromParent();
      game.items.remove(other);
    } else if (other is Chicken && !isFleeing) {
      // Scare the chicken
      other.onDisturbanceNearby();
    } else if (other is Dog && !isFleeing) {
      // Dogs always catch rats
      final awayDirection = (position - other.position).normalized();
      flee(awayDirection);
    } else if (other is Fence && !isFleeing && !_slippedThrough) {
      // Rats can slip through fences (50% chance) or go around
      final random = Random();
      if (random.nextDouble() < 0.4) {
        // Slip through - just slow down temporarily
        _slippedThrough = true;
        speed = 50;
      } else {
        // Try to go around
        avoidDefense(other.position);
      }
    }
  }
}

/// GermBubble disturbance - spawns randomly, needs Sprayer to clear.
class GermBubble extends Disturbance {
  GermBubble({required super.position}) : super(size: Vector2(56, 56)) {
    speed = 20; // Slow drifting
    alertRange = 80;
    strength = 1; // Easy to pop - requires 5 taps
  }

  /// Get effective speed - faster in rain!
  double get effectiveSpeed {
    if (game.currentModifier == 'rain') {
      return speed * 2.0; // Double speed in rain
    }
    return speed;
  }

  /// Timer for spreading germs.
  double _spreadTimer = 0;
  final double _spreadInterval = 3.0;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('disturbance_germ_bubble.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFleeing || shouldRemove) return;

    // Drift randomly
    _spreadTimer += dt;
    if (_spreadTimer >= _spreadInterval) {
      _spreadTimer = 0;
      // Change drift direction
      final random = Random();
      final angle = random.nextDouble() * 2 * pi;
      position += Vector2(cos(angle), sin(angle)) * 30;
    }

    // Slow drift in current direction (faster in rain!)
    final random = Random();
    position += Vector2(
      (random.nextDouble() - 0.5) * effectiveSpeed * dt,
      (random.nextDouble() - 0.5) * effectiveSpeed * dt,
    );

    // Keep within bounds using world coordinates
    final padding = 100.0;
    position.x = position.x.clamp(padding, game.worldSize.x - padding);
    position.y = position.y.clamp(
      padding + 100,
      game.worldSize.y - padding - 100,
    );

    // Alert nearby chickens
    alertNearbyChickens();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Chicken && !isFleeing) {
      // Make chicken sick (scared state)
      other.onDisturbanceContact();
    } else if (other is Sprayer && !isFleeing) {
      // Cleared by sprayer - remove
      shouldRemove = true;
      removeFromParent();
    }
  }
}

/// BirdShadow disturbance - flying, causes AOE panic, blocked by Net.
class BirdShadow extends Disturbance {
  BirdShadow({required super.position}) : super(size: Vector2(80, 80)) {
    speed = 100; // Fast flying
    alertRange = 200; // Large AOE panic
    strength = 3; // Very strong - requires 15 taps to scare away
  }

  /// Whether this bird is blocked by a net.
  bool isBlocked = false;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('disturbance_bird_shadow.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFleeing || shouldRemove || isBlocked) return;

    // Move toward center of chicken group
    final target = _findChickenCenter();
    if (target != null) {
      final direction = (target - position).normalized();
      position += direction * speed * dt;
    }

    // Cause AOE panic to nearby chickens
    _causePanic();
  }

  Vector2? _findChickenCenter() {
    if (game.chickens.isEmpty) return null;

    double sumX = 0, sumY = 0;
    for (final chicken in game.chickens) {
      sumX += chicken.position.x;
      sumY += chicken.position.y;
    }
    return Vector2(sumX / game.chickens.length, sumY / game.chickens.length);
  }

  void _causePanic() {
    for (final chicken in game.chickens) {
      final distance = position.distanceTo(chicken.position);
      if (distance < alertRange) {
        // Cause immediate panic (scared state) for all chickens in range
        if (chicken.state != ChickenState.scared &&
            chicken.state != ChickenState.hiding) {
          chicken.onDisturbanceContact();
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is NetCover && !isFleeing) {
      // Blocked by net - remove
      shouldRemove = true;
      removeFromParent();
    } else if (other is Bell) {
      // Scared by bell - flee
      final awayDirection = (position - other.position).normalized();
      flee(awayDirection);
    }
  }
}

/// Spawner for disturbances during a wave.
class DisturbanceSpawner extends Component with HasGameReference<CoopGame> {
  final int foxCount;
  final int ratCount;
  final int germCount;
  final int birdCount;
  final double spawnDuration;
  final double startDelay;

  double _elapsedTime = 0;
  int _foxSpawned = 0;
  int _ratSpawned = 0;
  int _germSpawned = 0;
  int _birdSpawned = 0;
  bool _started = false;
  final Random _random = Random();

  DisturbanceSpawner({
    required this.foxCount,
    this.ratCount = 0,
    this.germCount = 0,
    this.birdCount = 0,
    required this.spawnDuration,
    this.startDelay = 0,
  });

  int get _totalCount => foxCount + ratCount + germCount + birdCount;
  int get _totalSpawned =>
      _foxSpawned + _ratSpawned + _germSpawned + _birdSpawned;

  double get _spawnInterval =>
      _totalCount > 0 ? spawnDuration / _totalCount : spawnDuration;

  bool get isComplete => _totalSpawned >= _totalCount;

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;

    // Wait for start delay
    if (!_started) {
      if (_elapsedTime >= startDelay) {
        _started = true;
        _elapsedTime = 0;
      }
      return;
    }

    // Spawn disturbances at intervals
    if (_totalSpawned < _totalCount) {
      final nextSpawnTime = _totalSpawned * _spawnInterval;
      if (_elapsedTime >= nextSpawnTime) {
        _spawnNextDisturbance();
      }
    }
  }

  void _spawnNextDisturbance() {
    // Determine which type to spawn based on remaining counts
    final availableTypes = <DisturbanceType>[];
    if (_foxSpawned < foxCount) availableTypes.add(DisturbanceType.fox);
    if (_ratSpawned < ratCount) availableTypes.add(DisturbanceType.rat);
    if (_germSpawned < germCount) {
      availableTypes.add(DisturbanceType.germBubble);
    }
    if (_birdSpawned < birdCount) {
      availableTypes.add(DisturbanceType.birdShadow);
    }

    if (availableTypes.isEmpty) return;

    // Pick a random available type
    final type = availableTypes[_random.nextInt(availableTypes.length)];

    switch (type) {
      case DisturbanceType.fox:
        _spawnDisturbance(Fox(position: _getEdgeSpawnPosition()));
        _foxSpawned++;
      case DisturbanceType.rat:
        _spawnDisturbance(Rat(position: _getEdgeSpawnPosition()));
        _ratSpawned++;
      case DisturbanceType.germBubble:
        _spawnDisturbance(GermBubble(position: _getRandomSpawnPosition()));
        _germSpawned++;
      case DisturbanceType.birdShadow:
        _spawnDisturbance(BirdShadow(position: _getEdgeSpawnPosition()));
        _birdSpawned++;
    }
  }

  void _spawnDisturbance(Disturbance disturbance) {
    game.world.add(disturbance);
    game.disturbances.add(disturbance);
  }

  Vector2 _getEdgeSpawnPosition() {
    final edge = _random.nextInt(4);
    switch (edge) {
      case 0: // Top
        return Vector2(_random.nextDouble() * game.worldSize.x, -50);
      case 1: // Right
        return Vector2(
          game.worldSize.x + 50,
          _random.nextDouble() * game.worldSize.y,
        );
      case 2: // Bottom
        return Vector2(
          _random.nextDouble() * game.worldSize.x,
          game.worldSize.y + 50,
        );
      default: // Left
        return Vector2(-50, _random.nextDouble() * game.worldSize.y);
    }
  }

  Vector2 _getRandomSpawnPosition() {
    // Spawn germs anywhere in the playable area using world coordinates
    final padding = 100.0;
    return Vector2(
      padding + _random.nextDouble() * (game.worldSize.x - padding * 2),
      padding +
          100 +
          _random.nextDouble() * (game.worldSize.y - padding * 2 - 200),
    );
  }
}
