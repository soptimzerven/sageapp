import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../game/coop_game.dart';
import '../utils/audio_manager.dart';
import '../utils/progression_manager.dart';
import 'chicken.dart';
import 'disturbance.dart';
import 'items.dart';

/// Base class for all defense tools.
abstract class Defense extends SpriteComponent
    with HasGameReference<CoopGame>, CollisionCallbacks, DragCallbacks {
  Defense({
    required Vector2 position,
    required Vector2 size,
    required this.cost,
  }) : super(position: position, size: size, anchor: Anchor.center);

  /// Cost in coins to place this defense.
  final int cost;

  /// Whether this defense is currently being dragged.
  bool isDragging = false;

  /// Whether this defense has been placed.
  bool isPlaced = false;

  /// Original position before dragging started (for reverting).
  Vector2? _originalPosition;

  /// Visual indicator component for repositioning.
  _MoveIndicator? _moveIndicator;

  /// Pulse animation timer for placed defenses.
  double _indicatorTimer = 0;
  bool _showingIndicator = false;

  /// Called when the defense is placed.
  void onPlaced();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Show move indicator periodically for placed defenses during preparation
    if (isPlaced && game.gameState == GameState.preparation && !isDragging) {
      _indicatorTimer += dt;

      // Show indicator briefly every 3 seconds
      if (_indicatorTimer > 3.0 && !_showingIndicator) {
        _showMoveIndicator();
        _showingIndicator = true;
      }

      // Hide after 1.5 seconds
      if (_indicatorTimer > 4.5 && _showingIndicator) {
        _hideMoveIndicator();
        _showingIndicator = false;
        _indicatorTimer = 0;
      }
    } else if (_showingIndicator) {
      _hideMoveIndicator();
      _showingIndicator = false;
      _indicatorTimer = 0;
    }
  }

  void _showMoveIndicator() {
    if (_moveIndicator == null) {
      _moveIndicator = _MoveIndicator();
      add(_moveIndicator!);
    }
  }

  void _hideMoveIndicator() {
    _moveIndicator?.removeFromParent();
    _moveIndicator = null;
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (game.gameState != GameState.preparation) return;

    super.onDragStart(event);
    isDragging = true;
    _originalPosition = position.clone();
    opacity = 0.7;
    priority = 100; // Bring to front

    // Hide indicator while dragging
    _hideMoveIndicator();

    // Visual feedback - scale up slightly
    scale = Vector2.all(1.1);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return;

    position += event.localDelta;

    // Clamp to game bounds while dragging
    position.x = position.x.clamp(30, CoopGame.worldWidth - 30);
    position.y = position.y.clamp(60, CoopGame.worldHeight - 100);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!isDragging) return;

    super.onDragEnd(event);
    isDragging = false;
    opacity = 1.0;
    priority = 0; // Reset priority
    scale = Vector2.all(1.0); // Reset scale

    // Validate placement
    if (game.isValidPlacementPosition(position)) {
      // Valid placement
      if (!isPlaced) {
        onPlaced();
      } else {
        // Repositioned - play sound
        AudioManager().playFenceSound();
      }
    } else {
      // Invalid placement - revert with animation feel
      if (_originalPosition != null) {
        position = _originalPosition!;
      }
    }
    _originalPosition = null;
  }
}

/// Visual indicator showing a defense can be moved.
class _MoveIndicator extends PositionComponent {
  _MoveIndicator() : super(position: Vector2(0, -40), anchor: Anchor.center);

  double _timer = 0;
  double _opacity = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Fade in
    if (_timer < 0.3) {
      _opacity = _timer / 0.3;
    }
    // Stay visible
    else if (_timer < 1.2) {
      _opacity = 1.0;
    }
    // Fade out
    else if (_timer < 1.5) {
      _opacity = 1.0 - ((_timer - 1.2) / 0.3);
    } else {
      _opacity = 0;
    }

    // Bob up and down
    position.y = -40 + (sin(_timer * 4) * 3);
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0) return;

    // Draw move arrows icon
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, _opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw 4-way arrow indicator
    const arrowSize = 8.0;

    // Up arrow
    canvas.drawLine(
      const Offset(0, -arrowSize),
      const Offset(0, arrowSize),
      paint,
    );
    canvas.drawLine(
      const Offset(0, -arrowSize),
      const Offset(-4, -arrowSize + 4),
      paint,
    );
    canvas.drawLine(
      const Offset(0, -arrowSize),
      const Offset(4, -arrowSize + 4),
      paint,
    );

    // Down arrow
    canvas.drawLine(
      const Offset(0, arrowSize),
      const Offset(-4, arrowSize - 4),
      paint,
    );
    canvas.drawLine(
      const Offset(0, arrowSize),
      const Offset(4, arrowSize - 4),
      paint,
    );

    // Left arrow
    canvas.drawLine(
      const Offset(-arrowSize, 0),
      const Offset(arrowSize, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(-arrowSize, 0),
      const Offset(-arrowSize + 4, -4),
      paint,
    );
    canvas.drawLine(
      const Offset(-arrowSize, 0),
      const Offset(-arrowSize + 4, 4),
      paint,
    );

    // Right arrow
    canvas.drawLine(
      const Offset(arrowSize, 0),
      const Offset(arrowSize - 4, -4),
      paint,
    );
    canvas.drawLine(
      const Offset(arrowSize, 0),
      const Offset(arrowSize - 4, 4),
      paint,
    );

    // Background circle
    final bgPaint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, _opacity * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 14, bgPaint);

    // Redraw arrows on top of background
    canvas.drawLine(
      const Offset(0, -arrowSize),
      const Offset(0, arrowSize),
      paint,
    );
    canvas.drawLine(
      const Offset(-arrowSize, 0),
      const Offset(arrowSize, 0),
      paint,
    );
    // Arrow heads
    canvas.drawLine(
      const Offset(0, -arrowSize),
      const Offset(-3, -arrowSize + 3),
      paint,
    );
    canvas.drawLine(
      const Offset(0, -arrowSize),
      const Offset(3, -arrowSize + 3),
      paint,
    );
    canvas.drawLine(
      const Offset(0, arrowSize),
      const Offset(-3, arrowSize - 3),
      paint,
    );
    canvas.drawLine(
      const Offset(0, arrowSize),
      const Offset(3, arrowSize - 3),
      paint,
    );
    canvas.drawLine(
      const Offset(-arrowSize, 0),
      const Offset(-arrowSize + 3, -3),
      paint,
    );
    canvas.drawLine(
      const Offset(-arrowSize, 0),
      const Offset(-arrowSize + 3, 3),
      paint,
    );
    canvas.drawLine(
      const Offset(arrowSize, 0),
      const Offset(arrowSize - 3, -3),
      paint,
    );
    canvas.drawLine(
      const Offset(arrowSize, 0),
      const Offset(arrowSize - 3, 3),
      paint,
    );
  }
}

/// Fence defense - static barrier that blocks disturbances.
class Fence extends Defense {
  Fence({required super.position}) : super(size: Vector2(80, 80), cost: 30);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('defense_fence.png');
    add(RectangleHitbox());
  }

  /// Called when the fence is placed.
  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
  }
}

/// Dog defense - actively chases and repels disturbances.
class Dog extends Defense {
  Dog({required super.position}) : super(size: Vector2(72, 72), cost: 50);

  /// Movement speed when chasing.
  final double speed = 100;

  /// Base detection range for disturbances.
  final double _baseDetectionRange = 200;

  /// Get effective detection range with upgrades applied.
  double get detectionRange =>
      _baseDetectionRange *
      ProgressionManager().getRangeMultiplier(DefenseType.dog);

  /// Current target disturbance.
  Disturbance? _target;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('defense_guard_dog.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaced || isDragging) return;

    // Find and chase nearest disturbance
    _findTarget();

    if (_target != null && !_target!.shouldRemove && !_target!.isFleeing) {
      _chaseTarget(dt);
    }
  }

  void _findTarget() {
    _target = null;
    double minDistance = detectionRange;

    for (final disturbance in game.disturbances) {
      if (disturbance.shouldRemove || disturbance.isFleeing) continue;

      final distance = position.distanceTo(disturbance.position);
      if (distance < minDistance) {
        minDistance = distance;
        _target = disturbance;
      }
    }
  }

  void _chaseTarget(double dt) {
    if (_target == null) return;

    final direction = (_target!.position - position).normalized();
    position += direction * speed * dt;

    // Keep within bounds using world coordinates
    final padding = 50.0;
    position.x = position.x.clamp(padding, game.worldSize.x - padding);
    position.y = position.y.clamp(
      padding + 100,
      game.worldSize.y - padding - 100,
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Disturbance && !other.isFleeing) {
      // Make the disturbance flee
      final awayDirection = (other.position - position).normalized();
      other.flee(awayDirection);
      AudioManager().playBellSound(); // Bark sound
    }
  }

  /// Called when the dog is placed.
  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
  }
}

/// Bell defense - AOE scare that temporarily repels disturbances.
class Bell extends Defense {
  Bell({required super.position}) : super(size: Vector2(64, 64), cost: 40);

  /// Base range of the bell's AOE effect.
  final double _baseRange = 150;

  /// Get effective range with upgrades applied.
  double get range =>
      _baseRange * ProgressionManager().getRangeMultiplier(DefenseType.bell);

  /// Base cooldown between activations.
  final double _baseCooldown = 5.0;

  /// Get effective cooldown with upgrades applied.
  double get cooldown =>
      _baseCooldown *
      ProgressionManager().getCooldownMultiplier(DefenseType.bell);

  double _cooldownTimer = 0;
  bool _isOnCooldown = false;

  /// Whether the bell is currently active.
  bool _isRinging = false;
  double _ringTimer = 0;
  final double _ringDuration = 1.0;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('defense_alarm_bell.png');
    add(CircleHitbox(radius: _baseRange / 2, isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaced || isDragging) return;

    // Handle cooldown
    if (_isOnCooldown) {
      _cooldownTimer += dt;
      if (_cooldownTimer >= cooldown) {
        _isOnCooldown = false;
        _cooldownTimer = 0;
      }
    }

    // Handle ringing
    if (_isRinging) {
      _ringTimer += dt;
      if (_ringTimer >= _ringDuration) {
        _isRinging = false;
        _ringTimer = 0;
      }
    }

    // Auto-activate when disturbance is in range
    if (!_isOnCooldown && !_isRinging) {
      for (final disturbance in game.disturbances) {
        if (disturbance.shouldRemove || disturbance.isFleeing) continue;

        final distance = position.distanceTo(disturbance.position);
        if (distance < range) {
          _activate();
          break;
        }
      }
    }
  }

  void _activate() {
    _isRinging = true;
    _isOnCooldown = true;
    AudioManager().playBellSound();

    // Scare all disturbances in range
    for (final disturbance in game.disturbances) {
      if (disturbance.shouldRemove || disturbance.isFleeing) continue;

      final distance = position.distanceTo(disturbance.position);
      if (distance < range) {
        final awayDirection = (disturbance.position - position).normalized();
        disturbance.flee(awayDirection);
      }
    }
  }

  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
  }
}

/// LightPost defense - reduces fear rate in range (for night levels).
class LightPost extends Defense {
  LightPost({required super.position}) : super(size: Vector2(48, 80), cost: 35);

  /// Base range of the light's effect.
  final double _baseRange = 120;

  /// Get effective range with upgrades applied.
  double get range =>
      _baseRange *
      ProgressionManager().getRangeMultiplier(DefenseType.lightPost);

  /// Whether the light is currently active (can be disabled during power outage).
  bool isActive = true;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('defense_light_post.png');
    add(CircleHitbox(radius: _baseRange / 2, isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaced || isDragging || !isActive) return;

    // Calm chickens in range during night modifier
    if (game.currentModifier == 'night') {
      for (final chicken in game.chickens) {
        final distance = position.distanceTo(chicken.position);
        if (distance < range) {
          // Reduce fear effect - if chicken is alert, keep it calm
          if (chicken.state == ChickenState.alert) {
            chicken.setState(ChickenState.idle);
          }
        }
      }
    }
  }

  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
  }
}

/// NetCover defense - blocks flying disturbances (BirdShadow).
class NetCover extends Defense {
  NetCover({required super.position})
    : super(size: Vector2(100, 100), cost: 45);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('defense_net_cover.png');
    add(RectangleHitbox());
  }

  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
  }
}

/// Sprayer defense - clears germs on contact.
class Sprayer extends Defense {
  Sprayer({required super.position}) : super(size: Vector2(56, 56), cost: 35);

  /// Base range of the sprayer's effect.
  final double _baseRange = 80;

  /// Get effective range with upgrades applied.
  double get range =>
      _baseRange * ProgressionManager().getRangeMultiplier(DefenseType.sprayer);

  /// Base cooldown between sprays.
  final double _baseCooldown = 3.0;

  /// Get effective cooldown with upgrades applied.
  double get cooldown =>
      _baseCooldown *
      ProgressionManager().getCooldownMultiplier(DefenseType.sprayer);

  double _cooldownTimer = 0;
  bool _isOnCooldown = false;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('defense_cleaning_sprayer.png');
    add(CircleHitbox(radius: _baseRange / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaced || isDragging) return;

    // Handle cooldown
    if (_isOnCooldown) {
      _cooldownTimer += dt;
      if (_cooldownTimer >= cooldown) {
        _isOnCooldown = false;
        _cooldownTimer = 0;
      }
    }

    // Auto-spray when germ is in range
    if (!_isOnCooldown) {
      for (final disturbance in game.disturbances) {
        if (disturbance is GermBubble && !disturbance.shouldRemove) {
          final distance = position.distanceTo(disturbance.position);
          if (distance < range) {
            _spray(disturbance);
            break;
          }
        }
      }
    }
  }

  void _spray(GermBubble germ) {
    _isOnCooldown = true;
    germ.shouldRemove = true;
    germ.removeFromParent();
  }

  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
  }
}

/// FeedDispenser defense - places feed to calm chickens.
class FeedDispenser extends Defense {
  FeedDispenser({required super.position})
    : super(size: Vector2(56, 56), cost: 25);

  /// Base range of the dispenser's effect.
  final double _baseRange = 100;

  /// Get effective range with upgrades applied.
  double get range =>
      _baseRange *
      ProgressionManager().getRangeMultiplier(DefenseType.feedDispenser);

  /// Base interval between dispensing feed.
  final double _baseDispenseInterval = 8.0;

  /// Get effective dispense interval with upgrades applied (shorter is better).
  double get dispenseInterval =>
      _baseDispenseInterval *
      ProgressionManager().getCooldownMultiplier(DefenseType.feedDispenser);

  double _dispenseTimer = 0;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('item_feed.png');
    add(CircleHitbox(radius: _baseRange / 2, isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaced || isDragging) return;

    _dispenseTimer += dt;
    if (_dispenseTimer >= dispenseInterval) {
      _dispenseTimer = 0;
      _dispenseFeed();
    }
  }

  void _dispenseFeed() {
    // Drop feed near the dispenser
    final feed = Feed(position: position + Vector2(0, 30));
    game.world.add(feed);
    game.items.add(feed);
  }

  @override
  void onPlaced() {
    isPlaced = true;
    AudioManager().playFenceSound();
    // Dispense first feed immediately
    _dispenseFeed();
  }
}

/// Enum for defense types.
enum DefenseType {
  fence,
  dog,
  bell,
  lightPost,
  netCover,
  sprayer,
  feedDispenser,
}

/// Factory for creating defenses.
class DefenseFactory {
  static Defense create(DefenseType type, Vector2 position) {
    switch (type) {
      case DefenseType.fence:
        return Fence(position: position);
      case DefenseType.dog:
        return Dog(position: position);
      case DefenseType.bell:
        return Bell(position: position);
      case DefenseType.lightPost:
        return LightPost(position: position);
      case DefenseType.netCover:
        return NetCover(position: position);
      case DefenseType.sprayer:
        return Sprayer(position: position);
      case DefenseType.feedDispenser:
        return FeedDispenser(position: position);
    }
  }

  static int getCost(DefenseType type) {
    switch (type) {
      case DefenseType.fence:
        return 30;
      case DefenseType.dog:
        return 50;
      case DefenseType.bell:
        return 40;
      case DefenseType.lightPost:
        return 35;
      case DefenseType.netCover:
        return 45;
      case DefenseType.sprayer:
        return 35;
      case DefenseType.feedDispenser:
        return 25;
    }
  }

  static String getSpritePath(DefenseType type) {
    switch (type) {
      case DefenseType.fence:
        return 'defense_fence.png';
      case DefenseType.dog:
        return 'defense_guard_dog.png';
      case DefenseType.bell:
        return 'defense_alarm_bell.png';
      case DefenseType.lightPost:
        return 'defense_light_post.png';
      case DefenseType.netCover:
        return 'defense_net_cover.png';
      case DefenseType.sprayer:
        return 'defense_cleaning_sprayer.png';
      case DefenseType.feedDispenser:
        return 'item_feed.png';
    }
  }

  static String getName(DefenseType type) {
    switch (type) {
      case DefenseType.fence:
        return 'Fence';
      case DefenseType.dog:
        return 'Dog';
      case DefenseType.bell:
        return 'Bell';
      case DefenseType.lightPost:
        return 'Light';
      case DefenseType.netCover:
        return 'Net';
      case DefenseType.sprayer:
        return 'Sprayer';
      case DefenseType.feedDispenser:
        return 'Feed';
    }
  }

  /// Convert string tool name to DefenseType.
  static DefenseType? fromString(String name) {
    switch (name.toLowerCase()) {
      case 'fence':
        return DefenseType.fence;
      case 'dog':
        return DefenseType.dog;
      case 'bell':
        return DefenseType.bell;
      case 'light':
      case 'lightpost':
        return DefenseType.lightPost;
      case 'net':
      case 'netcover':
        return DefenseType.netCover;
      case 'sprayer':
        return DefenseType.sprayer;
      case 'feed':
      case 'feeddispenser':
        return DefenseType.feedDispenser;
      default:
        return null;
    }
  }
}
