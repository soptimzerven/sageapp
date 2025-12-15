import 'package:flutter/material.dart';

import '../game/coop_game.dart';

/// Pause menu overlay.
class PauseOverlay extends StatelessWidget {
  final CoopGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;
    final isCompact = isLandscape && isSmallHeight;

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              margin: EdgeInsets.symmetric(
                horizontal: isCompact ? 24 : 40,
                vertical: isCompact ? 12 : 24,
              ),
              constraints: BoxConstraints(
                maxWidth: isCompact ? screenSize.width * 0.7 : 400,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: isCompact
                  ? _buildCompactLayout(context)
                  : _buildNormalLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Normal portrait layout
  Widget _buildNormalLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause title
        const Icon(Icons.pause_circle, size: 80, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          'PAUSED',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 32),

        // Resume button
        _MenuButton(
          icon: Icons.play_arrow,
          label: 'RESUME',
          color: Colors.green,
          onPressed: () {
            game.resumeGame();
          },
        ),
        const SizedBox(height: 16),

        // How to Play button
        _MenuButton(
          icon: Icons.help_outline,
          label: 'HOW TO PLAY',
          color: Colors.blue,
          onPressed: () {
            _showHowToPlay(context);
          },
        ),
        const SizedBox(height: 16),

        // Exit to Menu button
        _MenuButton(
          icon: Icons.exit_to_app,
          label: 'EXIT TO MENU',
          color: Colors.red,
          onPressed: () {
            game.resumeGame(); // Resume first to clear pause state
            game.returnToMenu();
          },
        ),
      ],
    );
  }

  /// Compact landscape layout
  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact header - icon and title in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle, size: 40, color: Colors.orange),
            const SizedBox(width: 12),
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Buttons in a more compact arrangement
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _MenuButton(
                icon: Icons.play_arrow,
                label: 'RESUME',
                color: Colors.green,
                compact: true,
                onPressed: () {
                  game.resumeGame();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MenuButton(
                icon: Icons.help_outline,
                label: 'HELP',
                color: Colors.blue,
                compact: true,
                onPressed: () {
                  _showHowToPlay(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MenuButton(
                icon: Icons.exit_to_app,
                label: 'EXIT',
                color: Colors.red,
                compact: true,
                onPressed: () {
                  game.resumeGame();
                  game.returnToMenu();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHowToPlay(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;
    final isCompact = isLandscape && isSmallHeight;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 40,
          vertical: isCompact ? 12 : 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isCompact ? screenSize.width * 0.9 : 400,
            maxHeight: screenSize.height * 0.85,
          ),
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.orange,
                    size: isCompact ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How to Play',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 18 : 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 12 : 16),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HowToPlayItem(
                        icon: Icons.touch_app,
                        title: 'Place Defenses',
                        description:
                            'Drag defense tools from the bottom bar onto the field.',
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      _HowToPlayItem(
                        icon: Icons.open_with,
                        title: 'Reposition Defenses',
                        description:
                            'Drag placed defenses to move them to a better spot.',
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      _HowToPlayItem(
                        icon: Icons.ads_click,
                        title: 'Tap Enemies',
                        description:
                            'Tap on enemies to push them away! Stronger enemies need more taps.',
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      _HowToPlayItem(
                        icon: Icons.pets,
                        title: 'Protect Chickens',
                        description:
                            'Use fences to block and dogs to chase away threats.',
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      _HowToPlayItem(
                        icon: Icons.star,
                        title: 'Win Condition',
                        description:
                            'Keep 90% of chickens calm to pass and earn coins!',
                        compact: isCompact,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 12 : 16),
              // Close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'GOT IT',
                  style: TextStyle(fontSize: isCompact ? 14 : 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? null : double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 16,
            horizontal: compact ? 12 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HowToPlayItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool compact;

  const _HowToPlayItem({
    required this.icon,
    required this.title,
    required this.description,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: compact ? 18 : 24),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 13 : 16,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: compact ? 11 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
