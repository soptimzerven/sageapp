import '../components/defense.dart';

/// Manages player progression: permanent coins, tool unlocks, and upgrades.
/// This is a singleton that persists across game sessions (in memory).
class ProgressionManager {
  static final ProgressionManager _instance = ProgressionManager._internal();
  factory ProgressionManager() => _instance;
  ProgressionManager._internal();

  /// Total permanent coins earned across all levels.
  int _totalCoins = 0;
  int get totalCoins => _totalCoins;

  /// Highest level completed.
  int _highestLevelCompleted = 0;
  int get highestLevelCompleted => _highestLevelCompleted;

  /// Tool upgrade levels (0 = base, 1 = upgraded once, 2 = max upgrade).
  final Map<DefenseType, int> _toolUpgrades = {};

  /// Tools that have been permanently unlocked through progression.
  final Set<DefenseType> _unlockedTools = {
    DefenseType.fence, // Fence is always unlocked
    DefenseType.dog, // Dog is always unlocked
  };

  /// Get the upgrade level for a tool (0-2).
  int getUpgradeLevel(DefenseType type) => _toolUpgrades[type] ?? 0;

  /// Check if a tool is unlocked.
  bool isToolUnlocked(DefenseType type) => _unlockedTools.contains(type);

  /// Get all unlocked tools.
  Set<DefenseType> get unlockedTools => Set.from(_unlockedTools);

  /// Calculate coins earned for completing a level.
  /// Base coins + bonus for high scores.
  int calculateLevelReward(int levelNumber, double safetyScore) {
    if (safetyScore < 90) return 0; // No reward for failed levels

    // Base reward scales with level
    final baseReward = 10 + (levelNumber * 5);

    // Bonus for perfect scores
    int bonus = 0;
    if (safetyScore >= 100) {
      bonus = 20; // Perfect score bonus
    } else if (safetyScore >= 95) {
      bonus = 10; // Near-perfect bonus
    }

    return baseReward + bonus;
  }

  /// Award coins for completing a level.
  void awardLevelReward(int levelNumber, double safetyScore) {
    final reward = calculateLevelReward(levelNumber, safetyScore);
    _totalCoins += reward;

    // Update highest level if this is a new record
    if (safetyScore >= 90 && levelNumber > _highestLevelCompleted) {
      _highestLevelCompleted = levelNumber;
      _checkUnlocks();
    }
  }

  /// Check and apply tool unlocks based on progression.
  void _checkUnlocks() {
    // Unlock tools based on highest level completed
    // Level 3+: Bell unlocked
    if (_highestLevelCompleted >= 3) {
      _unlockedTools.add(DefenseType.bell);
    }
    // Level 4+: FeedDispenser unlocked
    if (_highestLevelCompleted >= 4) {
      _unlockedTools.add(DefenseType.feedDispenser);
    }
    // Level 5+: LightPost unlocked
    if (_highestLevelCompleted >= 5) {
      _unlockedTools.add(DefenseType.lightPost);
    }
    // Level 7+: Sprayer unlocked
    if (_highestLevelCompleted >= 7) {
      _unlockedTools.add(DefenseType.sprayer);
    }
    // Level 8+: NetCover unlocked
    if (_highestLevelCompleted >= 8) {
      _unlockedTools.add(DefenseType.netCover);
    }
  }

  /// Get the cost to upgrade a tool.
  int getUpgradeCost(DefenseType type) {
    final currentLevel = getUpgradeLevel(type);
    if (currentLevel >= 2) return 0; // Max level

    // Upgrade costs increase with level
    switch (currentLevel) {
      case 0:
        return 50; // First upgrade
      case 1:
        return 100; // Second upgrade
      default:
        return 0;
    }
  }

  /// Attempt to upgrade a tool. Returns true if successful.
  bool upgradeTool(DefenseType type) {
    final currentLevel = getUpgradeLevel(type);
    if (currentLevel >= 2) return false; // Already max level

    final cost = getUpgradeCost(type);
    if (_totalCoins < cost) return false; // Can't afford

    _totalCoins -= cost;
    _toolUpgrades[type] = currentLevel + 1;
    return true;
  }

  /// Get the range multiplier for a tool based on upgrade level.
  double getRangeMultiplier(DefenseType type) {
    final level = getUpgradeLevel(type);
    switch (level) {
      case 1:
        return 1.15; // 15% range increase
      case 2:
        return 1.30; // 30% range increase
      default:
        return 1.0;
    }
  }

  /// Get the cooldown multiplier for a tool based on upgrade level.
  /// Lower is better (faster cooldown).
  double getCooldownMultiplier(DefenseType type) {
    final level = getUpgradeLevel(type);
    switch (level) {
      case 1:
        return 0.85; // 15% faster cooldown
      case 2:
        return 0.70; // 30% faster cooldown
      default:
        return 1.0;
    }
  }

  /// Get upgrade description for a tool.
  String getUpgradeDescription(DefenseType type) {
    final level = getUpgradeLevel(type);
    switch (level) {
      case 0:
        return 'Upgrade: +15% range, -15% cooldown';
      case 1:
        return 'Max Upgrade: +30% range, -30% cooldown';
      case 2:
        return 'Fully Upgraded!';
      default:
        return '';
    }
  }

  /// Reset all progression (for testing or new game).
  void reset() {
    _totalCoins = 0;
    _highestLevelCompleted = 0;
    _toolUpgrades.clear();
    _unlockedTools.clear();
    _unlockedTools.add(DefenseType.fence);
    _unlockedTools.add(DefenseType.dog);
  }
}
