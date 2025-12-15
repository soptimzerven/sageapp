import 'package:flutter/material.dart';

import '../game/coop_game.dart';
import '../utils/audio_manager.dart';
import '../utils/progression_manager.dart';

/// Main menu overlay displayed when the game starts.
class MenuOverlay extends StatelessWidget {
  final CoopGame game;

  const MenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final progression = ProgressionManager();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/images/bg_menu.png', fit: BoxFit.cover),
          // Content overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: SafeArea(
              child: isLandscape && isSmallHeight
                  ? _buildLandscapeLayout(context, progression)
                  : _buildPortraitLayout(context, progression),
            ),
          ),
        ],
      ),
    );
  }

  /// Portrait layout - the original layout for taller screens
  Widget _buildPortraitLayout(
    BuildContext context,
    ProgressionManager progression,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top bar with coins
        _buildCoinDisplay(progression),
        const Spacer(flex: 1),
        // Logo
        Image.asset(
          'assets/images/logo.png',
          width: 280,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        // Title
        const Text(
          'Coop Defender',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Protect your chickens!',
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const Spacer(flex: 2),
        // Play button
        _PlayButton(
          onPressed: () {
            game.startGame();
          },
        ),
        const SizedBox(height: 24),
        // Level and progress info
        _buildLevelInfo(progression),
        const SizedBox(height: 16),
        // Bottom buttons row
        _buildMenuButtons(context, progression),
        const Spacer(flex: 1),
      ],
    );
  }

  /// Landscape layout - more compact horizontal layout for wide screens
  Widget _buildLandscapeLayout(
    BuildContext context,
    ProgressionManager progression,
  ) {
    return Row(
      children: [
        // Left side - Logo and title
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo (smaller in landscape)
              Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              // Title (smaller in landscape)
              const Text(
                'Coop Defender',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Protect your chickens!',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
        // Right side - Play button and menu options
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coin display
                  _buildCoinDisplayCompact(progression),
                  const SizedBox(height: 12),
                  // Play button (smaller in landscape)
                  _PlayButton(
                    onPressed: () {
                      game.startGame();
                    },
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  // Level info
                  _buildLevelInfoCompact(progression),
                  const SizedBox(height: 12),
                  // Menu buttons in a wrap for landscape
                  _buildMenuButtonsCompact(context, progression),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinDisplay(ProgressionManager progression) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${progression.totalCoins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinDisplayCompact(ProgressionManager progression) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            '${progression.totalCoins}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(ProgressionManager progression) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Level ${game.currentLevel}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (progression.highestLevelCompleted > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Best: Level ${progression.highestLevelCompleted}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelInfoCompact(ProgressionManager progression) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Level ${game.currentLevel}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (progression.highestLevelCompleted > 0) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 2),
            Text(
              '${progression.highestLevelCompleted}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuButtons(
    BuildContext context,
    ProgressionManager progression,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // How to Play button
        _MenuIconButton(
          icon: Icons.help_outline,
          label: 'How to Play',
          onPressed: () => _showHowToPlay(context),
        ),
        const SizedBox(width: 16),
        // Settings button
        _MenuIconButton(
          icon: Icons.settings,
          label: 'Settings',
          onPressed: () => _showSettings(context),
        ),
        // Upgrades button (only show if player has coins)
        if (progression.totalCoins > 0) ...[
          const SizedBox(width: 16),
          _MenuIconButton(
            icon: Icons.upgrade,
            label: 'Upgrades',
            onPressed: () => _showUpgradesDialog(context, progression),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuButtonsCompact(
    BuildContext context,
    ProgressionManager progression,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _MenuIconButton(
          icon: Icons.help_outline,
          label: 'How to Play',
          compact: true,
          onPressed: () => _showHowToPlay(context),
        ),
        _MenuIconButton(
          icon: Icons.settings,
          label: 'Settings',
          compact: true,
          onPressed: () => _showSettings(context),
        ),
        if (progression.totalCoins > 0)
          _MenuIconButton(
            icon: Icons.upgrade,
            label: 'Upgrades',
            compact: true,
            onPressed: () => _showUpgradesDialog(context, progression),
          ),
      ],
    );
  }

  void _showUpgradesDialog(
    BuildContext context,
    ProgressionManager progression,
  ) {
    showDialog(
      context: context,
      builder: (context) => _UpgradesDialog(progression: progression),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _HowToPlayDialog(),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(context: context, builder: (context) => const _SettingsDialog());
  }
}

/// Small icon button for menu options.
class _MenuIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool compact;

  const _MenuIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 8,
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: compact ? 14 : 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: compact ? 11 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// How to Play dialog.
class _HowToPlayDialog extends StatelessWidget {
  const _HowToPlayDialog();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;
    final isCompact = isLandscape && isSmallHeight;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 40,
        vertical: isCompact ? 12 : 24,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        constraints: BoxConstraints(
          maxWidth: isCompact ? screenSize.width * 0.9 : 400,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.orange.shade600,
                  size: isCompact ? 22 : 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Play',
                  style: TextStyle(
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 20),
            // Scrollable instructions
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HowToPlayItem(
                      icon: Icons.touch_app,
                      title: 'Place Defenses',
                      description:
                          'Drag defense tools from the bottom bar onto the field. You can place them anywhere!',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    _HowToPlayItem(
                      icon: Icons.open_with,
                      title: 'Reposition Defenses',
                      description:
                          'Already placed a defense? Drag it to move it to a better spot.',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    _HowToPlayItem(
                      icon: Icons.touch_app,
                      title: 'Tap Enemies',
                      description:
                          'During the wave, tap on enemies to push them away! Stronger enemies need more taps.',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    _HowToPlayItem(
                      icon: Icons.play_arrow,
                      title: 'Start Wave',
                      description:
                          'Press START when your defenses are ready. Enemies will try to scare your chickens!',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    _HowToPlayItem(
                      icon: Icons.pets,
                      title: 'Protect Chickens',
                      description:
                          'Chickens stay in the center. Use fences to block and dogs to chase away threats.',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    _HowToPlayItem(
                      icon: Icons.star,
                      title: 'Win Condition',
                      description:
                          'Keep at least 90% of your chickens calm to pass the level and earn coins!',
                      compact: isCompact,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isCompact ? 12 : 20),
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 24 : 32,
                  vertical: isCompact ? 8 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'GOT IT!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How to play item widget.
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
        Container(
          padding: EdgeInsets.all(compact ? 4 : 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.orange.shade600,
            size: compact ? 16 : 20,
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 12 : 14,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings dialog.
class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  bool _musicEnabled = true;

  @override
  void initState() {
    super.initState();
    _musicEnabled = AudioManager().isMusicEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;
    final isCompact = isLandscape && isSmallHeight;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 24 : 40,
        vertical: isCompact ? 12 : 24,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        constraints: BoxConstraints(
          maxWidth: 350,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.grey.shade700,
                  size: isCompact ? 22 : 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 16 : 24),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Music toggle
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: isCompact ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _musicEnabled ? Icons.music_note : Icons.music_off,
                            color: _musicEnabled ? Colors.green : Colors.grey,
                            size: isCompact ? 20 : 24,
                          ),
                          SizedBox(width: isCompact ? 8 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Background Music',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompact ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  _musicEnabled
                                      ? 'Music is on'
                                      : 'Music is off',
                                  style: TextStyle(
                                    fontSize: isCompact ? 10 : 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: isCompact ? 0.8 : 1.0,
                            child: Switch(
                              value: _musicEnabled,
                              activeTrackColor: Colors.green.shade200,
                              activeThumbColor: Colors.green,
                              onChanged: (value) {
                                setState(() {
                                  _musicEnabled = value;
                                  AudioManager().setMusicEnabled(value);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                    // Privacy Policy
                    InkWell(
                      onTap: () => _showPrivacyPolicy(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: isCompact ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: Colors.blue.shade600,
                              size: isCompact ? 20 : 24,
                            ),
                            SizedBox(width: isCompact ? 8 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isCompact ? 14 : 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'View our privacy policy',
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: isCompact ? 14 : 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isCompact ? 16 : 24),
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(fontSize: isCompact ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
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
            maxWidth: 400,
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
                    Icons.privacy_tip,
                    color: Colors.blue.shade600,
                    size: isCompact ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Privacy Policy',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Coop Defender Mini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isCompact ? 6 : 8),
                      Text(
                        'We respect your privacy and are committed to protecting it.',
                        style: TextStyle(fontSize: isCompact ? 12 : 14),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Text(
                        'Data Collection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 4),
                      Text(
                        '• We do NOT collect any personal data.\n'
                        '• We do NOT track your location.\n'
                        '• We do NOT use analytics or third-party services.\n'
                        '• We do NOT require any account or login.\n'
                        '• All game progress is stored locally on your device only.',
                        style: TextStyle(fontSize: isCompact ? 12 : 14),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Text(
                        'Your Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 4),
                      Text(
                        'Game progress (level, coins, upgrades) is saved locally on your device and is never transmitted to any server.',
                        style: TextStyle(fontSize: isCompact ? 12 : 14),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Text(
                        'Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isCompact ? 3 : 4),
                      Text(
                        'If you have any questions about this privacy policy, please contact the developer.',
                        style: TextStyle(fontSize: isCompact ? 12 : 14),
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
                  'OK',
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

class _PlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool compact;

  const _PlayButton({required this.onPressed, this.compact = false});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 36 : 60,
            vertical: isCompact ? 12 : 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 24 : 30),
          ),
          elevation: 8,
          shadowColor: Colors.orange.shade900,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, size: isCompact ? 24 : 32),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              'PLAY',
              style: TextStyle(
                fontSize: isCompact ? 20 : 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for viewing and purchasing tool upgrades.
class _UpgradesDialog extends StatefulWidget {
  final ProgressionManager progression;

  const _UpgradesDialog({required this.progression});

  @override
  State<_UpgradesDialog> createState() => _UpgradesDialogState();
}

class _UpgradesDialogState extends State<_UpgradesDialog> {
  @override
  Widget build(BuildContext context) {
    final unlockedTools = widget.progression.unlockedTools.toList();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallHeight = screenSize.height < 500;
    final isCompact = isLandscape && isSmallHeight;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 24 : 40,
        vertical: isCompact ? 12 : 24,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        constraints: BoxConstraints(
          maxWidth: isCompact ? screenSize.width * 0.8 : 350,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tool Upgrades',
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 12,
                    vertical: isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: isCompact ? 14 : 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.progression.totalCoins}',
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 20),
            // Tool list
            if (unlockedTools.isEmpty)
              Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 20),
                child: Text(
                  'Complete more levels to unlock tools!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isCompact ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: unlockedTools.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tool = unlockedTools[index];
                    return _UpgradeItem(
                      tool: tool,
                      progression: widget.progression,
                      onUpgrade: () => setState(() {}),
                      compact: isCompact,
                    );
                  },
                ),
              ),
            SizedBox(height: isCompact ? 12 : 20),
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(fontSize: isCompact ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual upgrade item in the list.
class _UpgradeItem extends StatelessWidget {
  final dynamic tool; // DefenseType
  final ProgressionManager progression;
  final VoidCallback onUpgrade;
  final bool compact;

  const _UpgradeItem({
    required this.tool,
    required this.progression,
    required this.onUpgrade,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = progression.getUpgradeLevel(tool);
    final cost = progression.getUpgradeCost(tool);
    final canAfford = progression.totalCoins >= cost;
    final isMaxed = level >= 2;

    // Get tool name
    String toolName;
    switch (tool.toString()) {
      case 'DefenseType.fence':
        toolName = 'Fence';
      case 'DefenseType.dog':
        toolName = 'Guard Dog';
      case 'DefenseType.bell':
        toolName = 'Alarm Bell';
      case 'DefenseType.lightPost':
        toolName = 'Light Post';
      case 'DefenseType.netCover':
        toolName = 'Net Cover';
      case 'DefenseType.sprayer':
        toolName = 'Sprayer';
      case 'DefenseType.feedDispenser':
        toolName = 'Feed Dispenser';
      default:
        toolName = 'Unknown';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
      child: Row(
        children: [
          // Tool info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      toolName,
                      style: TextStyle(
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    // Level indicators
                    Row(
                      children: List.generate(2, (i) {
                        return Container(
                          margin: EdgeInsets.only(right: compact ? 2 : 3),
                          width: compact ? 8 : 10,
                          height: compact ? 8 : 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < level
                                ? Colors.green
                                : Colors.grey.shade300,
                            border: Border.all(
                              color: i < level
                                  ? Colors.green.shade700
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  progression.getUpgradeDescription(tool),
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Upgrade button
          if (!isMaxed)
            ElevatedButton(
              onPressed: canAfford
                  ? () {
                      if (progression.upgradeTool(tool)) {
                        onUpgrade();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 4 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, size: compact ? 12 : 16),
                  SizedBox(width: compact ? 2 : 4),
                  Text('$cost', style: TextStyle(fontSize: compact ? 12 : 14)),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 4 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    size: compact ? 12 : 16,
                    color: Colors.green.shade700,
                  ),
                  SizedBox(width: compact ? 2 : 4),
                  Text(
                    'MAX',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 11 : 14,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
