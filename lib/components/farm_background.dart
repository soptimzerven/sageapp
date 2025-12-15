import 'package:flame/components.dart';

import '../game/coop_game.dart';

/// Background component that renders the farm ground.
class FarmBackground extends SpriteComponent with HasGameReference<CoopGame> {
  FarmBackground() : super(priority: -1, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('bg_farm_ground.png');
    // Initial size setup
    _updateBackgroundSize();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateBackgroundSize();
  }

  /// Update background to cover the entire visible camera area.
  void _updateBackgroundSize() {
    if (sprite == null) return;

    // Get the camera's visible world rect (the area the camera can see)
    final visibleRect = game.camera.visibleWorldRect;
    final viewWidth = visibleRect.width;
    final viewHeight = visibleRect.height;

    // Get the original sprite dimensions
    final spriteWidth = sprite!.srcSize.x;
    final spriteHeight = sprite!.srcSize.y;

    // Calculate scale factors to cover the visible area
    final scaleX = viewWidth / spriteWidth;
    final scaleY = viewHeight / spriteHeight;

    // Use the larger scale to ensure full coverage (like CSS background-size: cover)
    final scaleFactor = scaleX > scaleY ? scaleX : scaleY;

    // Apply the scale with some padding to ensure no gaps
    size = Vector2(
      spriteWidth * scaleFactor * 1.1,
      spriteHeight * scaleFactor * 1.1,
    );

    // Position at the center of the visible world (which is the camera's focus point)
    position = Vector2(visibleRect.center.dx, visibleRect.center.dy);
  }
}
