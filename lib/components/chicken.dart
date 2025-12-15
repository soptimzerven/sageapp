import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/coop_game.dart';
import '../utils/audio_manager.dart';

/// The different states a chicken can be in.
enum ChickenState { idle, alert, scared, happy, hiding }

/// Idle behavior types for chickens.
enum ChickenIdleBehavior { standing, pecking, walking }

/// Chicken component that can be in various emotional states.
class Chicken extends SpriteComponent
    with HasGameReference<CoopGame>, CollisionCallbacks {
  Chicken({required Vector2 position})
    : super(position: position, size: Vector2(48, 48), anchor: Anchor.center);

  /// Current state of the chicken.
  ChickenState _state = ChickenState.idle;
  ChickenState get state => _state;

  /// Current idle behavior.
  ChickenIdleBehavior _idleBehavior = ChickenIdleBehavior.standing;

  /// Sprites for different states.
  late Sprite _idleSprite;
  late Sprite _alertSprite;
  late Sprite _scaredSprite;
  late Sprite _happySprite;

  /// Status icon sprites.
  late Sprite _alertIconSprite;
  late Sprite _happyIconSprite;

  /// Status icon component displayed above the chicken.
  SpriteComponent? _statusIcon;

  /// Movement properties for wandering.
  final Random _random = Random();
  Vector2 _wanderDirection = Vector2.zero();
  double _wanderTimer = 0;
  double _wanderInterval = 3.0; // Change direction every 3 seconds
  final double _wanderSpeed = 15.0; // Slower wandering

  /// Timer for state recovery.
  double _stateTimer = 0;
  double _stateDuration = 0;

  /// Timer for idle behavior changes.
  double _idleBehaviorTimer = 0;
  double _idleBehaviorDuration = 2.0;

  /// Pecking animation timer.
  double _peckTimer = 0;
  bool _isPeckingDown = false;

  /// Playable area bounds (the poultry area).
  late Rect _bounds;

  /// Flag to track if this chicken has been scared during the wave.
  bool wasScaredDuringWave = false;

  /// Animation timer for icon bobbing effect.
  double _iconBobTimer = 0;

  @override
  Future<void> onLoad() async {
    // Load all state sprites
    _idleSprite = await Sprite.load('chicken_idle.png');
    _alertSprite = await Sprite.load('chicken_alert.png');
    _scaredSprite = await Sprite.load('chicken_scared.png');
    _happySprite = await Sprite.load('chicken_happy.png');

    // Load status icon sprites
    _alertIconSprite = await Sprite.load('icon_alert.png');
    _happyIconSprite = await Sprite.load('icon_happy.png');

    // Set initial sprite
    sprite = _idleSprite;

    // Get the poultry area bounds from the game
    _bounds = game.poultryArea;

    // Add hitbox for collision detection
    add(RectangleHitbox());

    // Initialize random wander direction
    _changeWanderDirection();

    // Start with random idle behavior
    _changeIdleBehavior();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle state timer
    if (_stateDuration > 0) {
      _stateTimer += dt;
      if (_stateTimer >= _stateDuration) {
        _stateTimer = 0;
        _stateDuration = 0;
        // Return to idle after temporary state
        if (_state == ChickenState.alert || _state == ChickenState.happy) {
          setState(ChickenState.idle);
        }
      }
    }

    // Update status icon bobbing animation
    if (_statusIcon != null) {
      _iconBobTimer += dt * 4; // Speed of bobbing
      final bobOffset = sin(_iconBobTimer) * 3; // Amplitude of 3 pixels
      _statusIcon!.position = Vector2(0, -35 + bobOffset);
    }

    // Handle hiding state (scaled down scared)
    if (_state == ChickenState.hiding) {
      // Chickens in hiding state don't move
      return;
    }

    // Only do idle behaviors and wander if in idle state
    if (_state == ChickenState.idle) {
      _updateIdleBehavior(dt);
      _updateWander(dt);
    } else if (_state == ChickenState.alert) {
      // Alert chickens move slower
      _updateWander(dt * 0.5);
    }

    // Always enforce bounds
    _enforceBounds();
  }

  /// Update idle behavior (pecking, standing, walking).
  void _updateIdleBehavior(double dt) {
    _idleBehaviorTimer += dt;

    // Change behavior periodically
    if (_idleBehaviorTimer >= _idleBehaviorDuration) {
      _idleBehaviorTimer = 0;
      _changeIdleBehavior();
    }

    // Handle pecking animation
    if (_idleBehavior == ChickenIdleBehavior.pecking) {
      _peckTimer += dt;
      if (_peckTimer > 0.3) {
        _peckTimer = 0;
        _isPeckingDown = !_isPeckingDown;
        // Simple pecking effect by adjusting scale
        if (_isPeckingDown) {
          scale = Vector2(1.0, 0.9);
        } else {
          scale = Vector2(1.0, 1.0);
        }
      }
    }
  }

  /// Change to a new random idle behavior.
  void _changeIdleBehavior() {
    final behaviors = ChickenIdleBehavior.values;
    _idleBehavior = behaviors[_random.nextInt(behaviors.length)];
    _idleBehaviorDuration = 2 + _random.nextDouble() * 4; // 2-6 seconds

    // Reset scale when changing behavior
    scale = Vector2.all(1.0);
    _peckTimer = 0;
    _isPeckingDown = false;

    // Walking behavior should have a direction
    if (_idleBehavior == ChickenIdleBehavior.walking) {
      _changeWanderDirection();
    } else {
      // Standing and pecking don't move
      _wanderDirection = Vector2.zero();
    }
  }

  /// Enforce that chicken stays within the poultry area bounds.
  void _enforceBounds() {
    // Strict bounds enforcement - chicken MUST stay inside
    // Chicken size is 48x48, anchor center (radius ~24)
    // Use margin of 40 to ensure sprite is fully inside the boundary
    final margin = 40.0;
    position.x = position.x.clamp(
      _bounds.left + margin,
      _bounds.right - margin,
    );
    position.y = position.y.clamp(
      _bounds.top + margin,
      _bounds.bottom - margin,
    );
  }

  /// Update wandering behavior.
  void _updateWander(double dt) {
    // Only move if walking behavior or alert
    if (_idleBehavior != ChickenIdleBehavior.walking &&
        _state == ChickenState.idle) {
      return;
    }

    _wanderTimer += dt;

    // Change direction periodically
    if (_wanderTimer >= _wanderInterval) {
      _wanderTimer = 0;
      _changeWanderDirection();
    }

    // Move in wander direction
    position += _wanderDirection * _wanderSpeed * dt;

    // Bounce off bounds
    final margin = 40.0;
    if (position.x < _bounds.left + margin) {
      _wanderDirection.x = _wanderDirection.x.abs();
    }
    if (position.x > _bounds.right - margin) {
      _wanderDirection.x = -_wanderDirection.x.abs();
    }
    if (position.y < _bounds.top + margin) {
      _wanderDirection.y = _wanderDirection.y.abs();
    }
    if (position.y > _bounds.bottom - margin) {
      _wanderDirection.y = -_wanderDirection.y.abs();
    }
  }

  /// Change to a new random wander direction.
  void _changeWanderDirection() {
    final angle = _random.nextDouble() * 2 * pi;
    _wanderDirection = Vector2(cos(angle), sin(angle));
    _wanderInterval = 3 + _random.nextDouble() * 4; // 3-7 seconds
  }

  /// Set the chicken's state and update sprite accordingly.
  void setState(ChickenState newState, {double duration = 0}) {
    if (_state == newState) return;

    final previousState = _state;
    _state = newState;
    _stateDuration = duration;
    _stateTimer = 0;

    // Remove existing status icon
    _removeStatusIcon();

    // Update sprite based on state
    switch (newState) {
      case ChickenState.idle:
        sprite = _idleSprite;
        scale = Vector2.all(1);
      case ChickenState.alert:
        sprite = _alertSprite;
        scale = Vector2.all(1);
        _showStatusIcon(_alertIconSprite);
      case ChickenState.scared:
        sprite = _scaredSprite;
        scale = Vector2.all(1);
        wasScaredDuringWave = true;
        _showStatusIcon(_alertIconSprite); // Show alert icon when scared too
      case ChickenState.happy:
        sprite = _happySprite;
        scale = Vector2.all(1);
        _showStatusIcon(_happyIconSprite);
      case ChickenState.hiding:
        sprite = _scaredSprite;
        scale = Vector2.all(0.7); // Scale down for hiding
        wasScaredDuringWave = true;
    }

    // Play chicken sound on certain state changes
    if (previousState != newState &&
        (newState == ChickenState.scared ||
            newState == ChickenState.alert ||
            newState == ChickenState.happy)) {
      AudioManager().playChickenSound();
    }
  }

  /// Show a status icon above the chicken.
  void _showStatusIcon(Sprite iconSprite) {
    _statusIcon = SpriteComponent(
      sprite: iconSprite,
      size: Vector2(24, 24),
      anchor: Anchor.center,
      position: Vector2(0, -45), // Position above the chicken
    );
    add(_statusIcon!);
    _iconBobTimer = 0;
  }

  /// Remove the current status icon.
  void _removeStatusIcon() {
    if (_statusIcon != null) {
      _statusIcon!.removeFromParent();
      _statusIcon = null;
    }
  }

  /// Called when a disturbance gets close.
  void onDisturbanceNearby() {
    if (_state == ChickenState.idle) {
      // Night modifier: chickens are more fearful and get scared faster!
      if (game.currentModifier == 'night') {
        setState(ChickenState.scared);
      } else {
        setState(ChickenState.alert, duration: 2);
      }
    }
  }

  /// Called when a disturbance touches/scares this chicken.
  void onDisturbanceContact() {
    setState(ChickenState.scared);
    // After being scared, transition to hiding
    Future.delayed(const Duration(seconds: 2), () {
      if (_state == ChickenState.scared) {
        setState(ChickenState.hiding);
      }
    });
  }

  /// Called to calm the chicken (e.g., after feeding or threat removed).
  void calm() {
    if (_state == ChickenState.scared || _state == ChickenState.hiding) {
      setState(ChickenState.happy, duration: 3);
    }
  }

  /// Reset chicken state for a new wave.
  void resetForNewWave() {
    wasScaredDuringWave = false;
    setState(ChickenState.idle);
  }
}
