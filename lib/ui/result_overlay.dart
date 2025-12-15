import 'package:flutter/material.dart';

import '../game/coop_game.dart';
import '../game/level_data.dart';
import '../utils/progression_manager.dart';

/// Result overlay displayed after a wave ends.
class ResultOverlay extends StatelessWidget {
  final CoopGame game;

  const ResultOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isSuccess = game.safetyScore >= 90;
    final isLastLevel = game.currentLevel >= LevelData.totalLevels;
    final coinsEarned = game.lastLevelReward;
    final totalCoins = ProgressionManager().totalCoins;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;
    final isCompact = isLandscape && isSmallHeight;

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.all(isCompact ? 16 : 32),
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              constraints: BoxConstraints(
                maxWidth: isCompact ? screenSize.width * 0.85 : 400,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: isCompact
                  ? _buildCompactLayout(
                      context,
                      isSuccess,
                      isLastLevel,
                      coinsEarned,
                      totalCoins,
                    )
                  : _buildNormalLayout(
                      context,
                      isSuccess,
                      isLastLevel,
                      coinsEarned,
                      totalCoins,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalLayout(
    BuildContext context,
    bool isSuccess,
    bool isLastLevel,
    int coinsEarned,
    int totalCoins,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Result icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
          ),
          child: Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            size: 60,
            color: isSuccess ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 24),
        // Result text
        Text(
          isSuccess ? 'Success!' : 'Try Again!',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 16),
        // Safety score
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Safety Score: ',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            Text(
              '${game.safetyScore.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(game.safetyScore),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Level info
        Text(
          'Level ${game.currentLevel}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        // Coins earned (only show if successful)
        if (isSuccess) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '+$coinsEarned',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'coins earned!',
                  style: TextStyle(fontSize: 14, color: Colors.amber.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Total coins
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings, color: Colors.grey, size: 18),
              const SizedBox(width: 4),
              Text(
                'Total: $totalCoins coins',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
        // Required score hint
        if (!isSuccess) ...[
          const SizedBox(height: 4),
          Text(
            'Need 90% to pass',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 24),
        // Buttons
        _buildButtons(context, isSuccess, isLastLevel, compact: false),
      ],
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    bool isSuccess,
    bool isLastLevel,
    int coinsEarned,
    int totalCoins,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side - icon and result
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                size: 36,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess ? 'Success!' : 'Try Again!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        // Right side - score and buttons
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safety score and level in a row
              Row(
                children: [
                  Text(
                    '${game.safetyScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(game.safetyScore),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Level ${game.currentLevel}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Coins earned
              if (isSuccess)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$coinsEarned',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Need 90% to pass',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 12),
              // Buttons
              _buildButtons(context, isSuccess, isLastLevel, compact: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(
    BuildContext context,
    bool isSuccess,
    bool isLastLevel, {
    required bool compact,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu button
        OutlinedButton(
          onPressed: () {
            game.returnToMenu();
          },
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 24,
              vertical: compact ? 8 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home, size: compact ? 18 : 24),
              if (!compact) ...[const SizedBox(width: 8), const Text('Menu')],
            ],
          ),
        ),
        SizedBox(width: compact ? 8 : 16),
        // Continue/Retry button
        Flexible(
          child: ElevatedButton(
            onPressed: () {
              if (isSuccess && !isLastLevel) {
                game.nextLevel();
              } else {
                game.retryLevel();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 32,
                vertical: compact ? 8 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess && !isLastLevel
                      ? Icons.arrow_forward
                      : Icons.refresh,
                  size: compact ? 18 : 24,
                ),
                SizedBox(width: compact ? 4 : 8),
                Text(
                  isSuccess ? (isLastLevel ? 'Again' : 'Next') : 'Retry',
                  style: TextStyle(
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
