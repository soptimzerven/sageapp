/// Data class representing a wave of disturbances.
class WaveData {
  /// Number of foxes in this wave.
  final int foxCount;

  /// Number of rats in this wave.
  final int ratCount;

  /// Number of germ bubbles in this wave.
  final int germCount;

  /// Number of bird shadows in this wave.
  final int birdCount;

  /// Duration in seconds over which disturbances spawn.
  final double spawnDuration;

  /// Delay in seconds before this wave starts.
  final double startDelay;

  const WaveData({
    this.foxCount = 0,
    this.ratCount = 0,
    this.germCount = 0,
    this.birdCount = 0,
    required this.spawnDuration,
    this.startDelay = 0,
  });
}

/// Data class representing a level configuration.
class Level {
  /// Level number (1-indexed).
  final int number;

  /// Number of chickens to protect.
  final int chickens;

  /// Coin budget for placing defenses.
  final int budget;

  /// List of waves in this level.
  final List<WaveData> waves;

  /// Available defense tools for this level.
  final List<String> availableTools;

  /// Optional environmental modifier (e.g., 'night', 'rain').
  final String? modifier;

  const Level({
    required this.number,
    required this.chickens,
    required this.budget,
    required this.waves,
    required this.availableTools,
    this.modifier,
  });
}

/// Level definitions (10 levels).
/// Chicken counts scale from 10 (early levels) to 20 (later levels).
class LevelData {
  static const List<Level> levels = [
    // Level 1: Tutorial - Easy intro with Fox only
    Level(
      number: 1,
      chickens: 10,
      budget: 150,
      waves: [WaveData(foxCount: 3, spawnDuration: 12)],
      availableTools: ['fence', 'dog'],
    ),
    // Level 2: Getting harder with more foxes
    Level(
      number: 2,
      chickens: 10,
      budget: 180,
      waves: [
        WaveData(foxCount: 4, spawnDuration: 14),
        WaveData(foxCount: 3, spawnDuration: 10, startDelay: 6),
      ],
      availableTools: ['fence', 'dog'],
    ),
    // Level 3: Introduce Rat
    Level(
      number: 3,
      chickens: 12,
      budget: 200,
      waves: [WaveData(foxCount: 3, ratCount: 3, spawnDuration: 16)],
      availableTools: ['fence', 'dog', 'feed'],
    ),
    // Level 4: More rats and foxes
    Level(
      number: 4,
      chickens: 12,
      budget: 220,
      waves: [
        WaveData(foxCount: 4, ratCount: 3, spawnDuration: 16),
        WaveData(foxCount: 3, ratCount: 4, spawnDuration: 14, startDelay: 6),
      ],
      availableTools: ['fence', 'dog', 'feed'],
    ),
    // Level 5: Introduce Bell defense
    Level(
      number: 5,
      chickens: 14,
      budget: 250,
      waves: [
        WaveData(foxCount: 5, ratCount: 4, spawnDuration: 20),
        WaveData(foxCount: 4, ratCount: 3, spawnDuration: 14, startDelay: 8),
      ],
      availableTools: ['fence', 'dog', 'feed', 'bell'],
    ),
    // Level 6: Night level - introduce LightPost
    Level(
      number: 6,
      chickens: 14,
      budget: 280,
      waves: [
        WaveData(foxCount: 5, ratCount: 3, spawnDuration: 20),
        WaveData(foxCount: 4, ratCount: 4, spawnDuration: 16, startDelay: 6),
      ],
      availableTools: ['fence', 'dog', 'light', 'feed'],
      modifier: 'night',
    ),
    // Level 7: Night with more threats
    Level(
      number: 7,
      chickens: 16,
      budget: 300,
      waves: [
        WaveData(foxCount: 6, ratCount: 4, spawnDuration: 22),
        WaveData(foxCount: 4, ratCount: 5, spawnDuration: 16, startDelay: 8),
      ],
      availableTools: ['fence', 'dog', 'light', 'bell', 'feed'],
      modifier: 'night',
    ),
    // Level 8: Mixed disturbances - introduce Germs and Sprayer
    Level(
      number: 8,
      chickens: 16,
      budget: 320,
      waves: [
        WaveData(foxCount: 4, ratCount: 3, germCount: 4, spawnDuration: 22),
        WaveData(
          foxCount: 3,
          ratCount: 4,
          germCount: 3,
          spawnDuration: 18,
          startDelay: 8,
        ),
      ],
      availableTools: ['fence', 'dog', 'sprayer', 'feed', 'bell'],
      modifier: 'rain',
    ),
    // Level 9: Introduce Bird Shadow and Net
    Level(
      number: 9,
      chickens: 18,
      budget: 350,
      waves: [
        WaveData(foxCount: 4, ratCount: 3, birdCount: 3, spawnDuration: 24),
        WaveData(
          foxCount: 4,
          ratCount: 4,
          birdCount: 2,
          germCount: 3,
          spawnDuration: 20,
          startDelay: 8,
        ),
      ],
      availableTools: ['fence', 'dog', 'net', 'sprayer', 'bell', 'feed'],
    ),
    // Level 10: Ultimate challenge - all disturbances, all tools
    Level(
      number: 10,
      chickens: 20,
      budget: 400,
      waves: [
        WaveData(
          foxCount: 5,
          ratCount: 4,
          germCount: 3,
          birdCount: 3,
          spawnDuration: 28,
        ),
        WaveData(
          foxCount: 4,
          ratCount: 5,
          germCount: 4,
          birdCount: 3,
          spawnDuration: 22,
          startDelay: 10,
        ),
        WaveData(
          foxCount: 3,
          ratCount: 3,
          germCount: 3,
          birdCount: 2,
          spawnDuration: 18,
          startDelay: 15,
        ),
      ],
      availableTools: [
        'fence',
        'dog',
        'bell',
        'light',
        'net',
        'sprayer',
        'feed',
      ],
      modifier: 'night',
    ),
  ];

  /// Get a level by number (1-indexed).
  static Level getLevel(int number) {
    if (number < 1 || number > levels.length) {
      return levels.first;
    }
    return levels[number - 1];
  }

  /// Total number of available levels.
  static int get totalLevels => levels.length;
}
