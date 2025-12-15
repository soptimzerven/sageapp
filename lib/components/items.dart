import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/coop_game.dart';
import 'chicken.dart';

/// Base class for all items in the game.
abstract class Item extends SpriteComponent
    with HasGameReference<CoopGame>, CollisionCallbacks {
  Item({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);
}

/// Egg item - spawns when chicken is productive, adds to score.
class Egg extends Item {
  Egg({required super.position}) : super(size: Vector2(32, 32));

  /// Points this egg is worth.
  final int points = 10;

  /// Timer for egg lifetime.
  double _lifetimeTimer = 0;
  final double lifetime = 30.0; // Eggs last 30 seconds

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('item_egg.png');
    add(RectangleHitbox(isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifetimeTimer += dt;
    if (_lifetimeTimer >= lifetime) {
      // Egg expired
      removeFromParent();
      game.items.remove(this);
    }
  }
}

/// Feed item - dropped by dispenser, chickens eat to become happy.
class Feed extends Item {
  Feed({required super.position}) : super(size: Vector2(40, 40));

  /// Timer for feed lifetime.
  double _lifetimeTimer = 0;
  final double lifetime = 20.0; // Feed lasts 20 seconds

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('item_feed.png');
    add(CircleHitbox(isSolid: false));
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifetimeTimer += dt;
    if (_lifetimeTimer >= lifetime) {
      // Feed expired
      removeFromParent();
      game.items.remove(this);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Chicken) {
      // Chicken eats the feed and becomes happy
      other.calm();
      removeFromParent();
      game.items.remove(this);
    }
  }
}
