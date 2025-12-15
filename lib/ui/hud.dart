import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/defense.dart';
import '../game/coop_game.dart';

/// Heads-Up Display overlay for the game.
class HudOverlay extends StatefulWidget {
  final CoopGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  /// Currently dragging defense type.
  DefenseType? _draggingType;

  @override
  void initState() {
    super.initState();
    // Listen to game updates
    widget.game.addListener(_onGameUpdate);
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameUpdate);
    super.dispose();
  }

  void _onGameUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Convert screen position to game world position.
  Vector2 _screenToWorld(Offset screenPosition, BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Calculate the game viewport scaling
    final scaleX = CoopGame.worldWidth / size.width;
    final scaleY = CoopGame.worldHeight / size.height;

    return Vector2(screenPosition.dx * scaleX, screenPosition.dy * scaleY);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Drag target overlay (covers the entire screen for drag detection)
          if (_draggingType != null)
            Positioned.fill(
              child: DragTarget<DefenseType>(
                onAcceptWithDetails: (details) {
                  // Place defense at drop location
                  // Offset by 40 (half of 80px feedback size) to center it
                  final centerOffset = details.offset + const Offset(40, 40);
                  final worldPos = _screenToWorld(centerOffset, context);
                  widget.game.completeDraggingDefense(worldPos);
                  setState(() {
                    _draggingType = null;
                  });
                },
                onLeave: (_) {
                  // Cancel if dragged outside
                },
                onMove: (details) {
                  // Update defense position while dragging
                  // Offset by 40 (half of 80px feedback size) to center it
                  final centerOffset = details.offset + const Offset(40, 40);
                  final worldPos = _screenToWorld(centerOffset, context);
                  widget.game.updateDraggingDefense(worldPos);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(color: Colors.transparent);
                },
              ),
            ),
          // Main HUD content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(game: widget.game),
                const Spacer(),
                // Placement hint when dragging
                if (_draggingType != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Drag to place defense around the poultry area',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Bottom bar (tool palette)
                if (widget.game.gameState == GameState.preparation)
                  _BottomBar(
                    game: widget.game,
                    onDragStarted: (type) {
                      setState(() {
                        _draggingType = type;
                      });
                      // Start dragging in game
                      final center = Vector2(
                        CoopGame.worldWidth / 2,
                        CoopGame.worldHeight / 2,
                      );
                      widget.game.startDraggingDefense(type, center);
                    },
                    onDragEnded: () {
                      if (_draggingType != null) {
                        widget.game.cancelDraggingDefense();
                        setState(() {
                          _draggingType = null;
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top bar showing coins and safety score.
class _TopBar extends StatelessWidget {
  final CoopGame game;

  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Coins
          _StatCard(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            value: '${game.coins}',
            label: 'Coins',
          ),
          // Level and Pause button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${game.currentLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Pause button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    game.pauseGame();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Safety Score
          _StatCard(
            icon: Icons.security,
            iconColor: _getScoreColor(game.safetyScore),
            value: '${game.safetyScore.toStringAsFixed(0)}%',
            label: 'Safety',
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom bar with tool palette and start wave button.
class _BottomBar extends StatefulWidget {
  final CoopGame game;
  final void Function(DefenseType type) onDragStarted;
  final VoidCallback onDragEnded;

  const _BottomBar({
    required this.game,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _instructionFadeController;
  late Animation<double> _instructionOpacity;
  bool _showInstruction = true;

  @override
  void initState() {
    super.initState();
    // Fade out instruction text after 4 seconds
    _instructionFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _instructionOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _instructionFadeController,
        curve: Curves.easeOut,
      ),
    );

    // Start fade-out after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _instructionFadeController.forward().then((_) {
          if (mounted) {
            setState(() {
              _showInstruction = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _instructionFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableTools = widget.game.availableDefenseTypes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Modifier indicator (if any)
          if (widget.game.currentModifier != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getModifierColor(widget.game.currentModifier!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getModifierIcon(widget.game.currentModifier!),
                color: Colors.white,
                size: 14,
              ),
            ),
          // Tool palette with draggable items - compact horizontal layout
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...availableTools.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _DraggableToolButton(
                        game: widget.game,
                        type: type,
                        icon:
                            'assets/images/${DefenseFactory.getSpritePath(type)}',
                        name: DefenseFactory.getName(type),
                        cost: DefenseFactory.getCost(type),
                        onDragStarted: () => widget.onDragStarted(type),
                        onDragEnded: widget.onDragEnded,
                      ),
                    );
                  }),
                  // Instruction hint (compact, inline with tools)
                  if (_showInstruction)
                    FadeTransition(
                      opacity: _instructionOpacity,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Drag to place',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Start wave button - compact version
          ElevatedButton(
            onPressed: () {
              widget.game.startWave();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: 20),
                SizedBox(width: 4),
                Text(
                  'START',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _getModifierColor(String modifier) {
    switch (modifier) {
      case 'night':
        return Colors.indigo.shade700;
      case 'rain':
        return Colors.blueGrey.shade600;
      case 'wind':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  static IconData _getModifierIcon(String modifier) {
    switch (modifier) {
      case 'night':
        return Icons.nightlight_round;
      case 'rain':
        return Icons.water_drop;
      case 'wind':
        return Icons.air;
      default:
        return Icons.warning;
    }
  }
}

/// Draggable tool button for placing defenses via drag-and-drop.
class _DraggableToolButton extends StatefulWidget {
  final CoopGame game;
  final DefenseType type;
  final String icon;
  final String name;
  final int cost;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const _DraggableToolButton({
    required this.game,
    required this.type,
    required this.icon,
    required this.name,
    required this.cost,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  State<_DraggableToolButton> createState() => _DraggableToolButtonState();
}

class _DraggableToolButtonState extends State<_DraggableToolButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Subtle pulse animation to indicate draggability
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = widget.game.coins >= widget.cost;
    final isSelected = widget.game.selectedDefenseType == widget.type;

    final buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.orange.withValues(alpha: 0.8)
            : (canAfford
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: canAfford
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool icon - smaller size
          Opacity(
            opacity: canAfford ? 1.0 : 0.5,
            child: Image.asset(widget.icon, width: 36, height: 36),
          ),
          const SizedBox(height: 2),
          // Tool name
          Text(
            widget.name,
            style: TextStyle(
              color: canAfford ? Colors.white : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Cost - compact
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                color: canAfford ? Colors.amber : Colors.grey,
                size: 10,
              ),
              const SizedBox(width: 1),
              Text(
                '${widget.cost}',
                style: TextStyle(
                  color: canAfford ? Colors.amber : Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!canAfford) {
      return buttonContent;
    }

    // Wrap affordable items with pulse animation
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Draggable<DefenseType>(
            data: widget.type,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: widget.onDragStarted,
            onDragEnd: (_) => widget.onDragEnded(),
            onDraggableCanceled: (velocity, offset) => widget.onDragEnded(),
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Image.asset(widget.icon, width: 44, height: 44),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.4, child: buttonContent),
            child: GestureDetector(
              onTap: () {
                // Allow tap to select (for click-to-place fallback)
                widget.game.selectDefenseType(widget.type);
              },
              child: buttonContent,
            ),
          ),
        );
      },
    );
  }
}
