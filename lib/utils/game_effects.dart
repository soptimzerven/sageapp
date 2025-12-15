import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Extension to add shake effect to CameraComponent's viewfinder.
extension CameraShakeEffect on CameraComponent {
  /// Apply a shake effect to the camera.
  void shake({double intensity = 10.0, int shakes = 6}) {
    final random = Random();
    final effects = <Effect>[];

    for (int i = 0; i < shakes; i++) {
      final offsetX = (random.nextDouble() - 0.5) * intensity * 2;
      final offsetY = (random.nextDouble() - 0.5) * intensity * 2;

      effects.add(
        MoveEffect.by(
          Vector2(offsetX, offsetY),
          EffectController(duration: 0.04),
        ),
      );
    }

    // Return to original position at the end
    effects.add(
      MoveEffect.by(Vector2.zero(), EffectController(duration: 0.04)),
    );

    viewfinder.add(SequenceEffect(effects));
  }
}

/// Creates a confetti/celebration particle effect for success.
class SuccessParticles extends ParticleSystemComponent {
  SuccessParticles({required Vector2 screenSize})
    : super(
        position: Vector2(screenSize.x / 2, screenSize.y / 3),
        particle: _createConfettiParticle(screenSize),
      );

  static Particle _createConfettiParticle(Vector2 screenSize) {
    final random = Random();

    // Festive colors for celebration
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.lightBlue,
      Colors.purple,
      Colors.red,
    ];

    return Particle.generate(
      count: 50,
      lifespan: 2.5,
      generator: (i) {
        final color = colors[random.nextInt(colors.length)];
        final angle = random.nextDouble() * 2 * pi;
        final speed = 100 + random.nextDouble() * 150;
        final size = 4 + random.nextDouble() * 6;

        return AcceleratedParticle(
          acceleration: Vector2(0, 150), // Gravity
          speed: Vector2(cos(angle) * speed, sin(angle) * speed - 100),
          position: Vector2((random.nextDouble() - 0.5) * 100, 0),
          child: ComputedParticle(
            lifespan: 2.5,
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final opacity = 1.0 - (progress * 0.5); // Fade out slowly
              final rotation = progress * 4 * pi; // Spin

              canvas.save();
              canvas.rotate(rotation);

              // Draw a small rectangle (confetti piece)
              final rect = Rect.fromCenter(
                center: Offset.zero,
                width: size,
                height: size * 0.6,
              );

              canvas.drawRect(
                rect,
                Paint()
                  ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
                  ..style = PaintingStyle.fill,
              );

              canvas.restore();
            },
          ),
        );
      },
    );
  }
}

/// Creates a burst of stars for level completion.
class StarBurstParticles extends ParticleSystemComponent {
  StarBurstParticles({required Vector2 position})
    : super(position: position, particle: _createStarBurst());

  static Particle _createStarBurst() {
    final random = Random();

    return Particle.generate(
      count: 12,
      lifespan: 1.5,
      generator: (i) {
        final angle = (i / 12) * 2 * pi;
        final speed = 80 + random.nextDouble() * 40;
        final starColor = i % 2 == 0 ? Colors.yellow : Colors.orange;

        return AcceleratedParticle(
          acceleration: Vector2(0, 50),
          speed: Vector2(cos(angle) * speed, sin(angle) * speed),
          child: ComputedParticle(
            lifespan: 1.5,
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final scale = 1.0 - progress;
              final opacity = 1.0 - progress;

              _drawStar(
                canvas,
                Offset.zero,
                8 * scale,
                5,
                starColor.withValues(alpha: opacity.clamp(0.0, 1.0)),
              );
            },
          ),
        );
      },
    );
  }

  static void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    int points,
    Color color,
  ) {
    final path = Path();
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * pi / points) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}

/// Creates a subtle sparkle effect.
class SparkleParticles extends ParticleSystemComponent {
  SparkleParticles({required Vector2 position})
    : super(position: position, particle: _createSparkle());

  static Particle _createSparkle() {
    final random = Random();

    return Particle.generate(
      count: 8,
      lifespan: 0.8,
      generator: (i) {
        final angle = random.nextDouble() * 2 * pi;
        final speed = 30 + random.nextDouble() * 30;

        return AcceleratedParticle(
          acceleration: Vector2(0, -20),
          speed: Vector2(cos(angle) * speed, sin(angle) * speed),
          child: ComputedParticle(
            lifespan: 0.8,
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final scale = (1.0 - progress) * (0.5 + progress * 0.5);
              final opacity = 1.0 - progress;

              canvas.drawCircle(
                Offset.zero,
                3 * scale,
                Paint()
                  ..color = Colors.white.withValues(
                    alpha: opacity.clamp(0.0, 1.0),
                  )
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
              );
            },
          ),
        );
      },
    );
  }
}
