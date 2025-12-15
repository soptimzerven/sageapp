import 'dart:async';
import 'dart:math';

import 'package:flame_audio/flame_audio.dart';

/// Centralized audio manager for the game.
/// Handles background music, sound effects, and ambient sounds.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final Random _random = Random();
  bool _isMusicPlaying = false;

  /// Whether music is enabled by the user.
  bool _isMusicEnabled = true;
  bool get isMusicEnabled => _isMusicEnabled;

  /// Timer for ambient chicken sounds during gameplay.
  Timer? _ambientChickenTimer;
  bool _isAmbientActive = false;

  /// Set music enabled state.
  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
      stopAmbientSounds();
    }
  }

  /// Pre-load all audio assets for faster playback.
  Future<void> preloadAll() async {
    await FlameAudio.audioCache.loadAll([
      'bgsong.mp3',
      'bell.ogg',
      'chicken.ogg',
      'chickenv2.ogg',
      'chickenv3.ogg',
      'fence.ogg',
      'success.ogg',
      'fail.ogg',
    ]);
  }

  /// Play background music on loop.
  void playBackgroundMusic() {
    if (!_isMusicPlaying && _isMusicEnabled) {
      FlameAudio.bgm.play('bgsong.mp3', volume: 0.5);
      _isMusicPlaying = true;
    }
  }

  /// Stop background music.
  void stopBackgroundMusic() {
    FlameAudio.bgm.stop();
    _isMusicPlaying = false;
  }

  /// Pause background music.
  void pauseBackgroundMusic() {
    FlameAudio.bgm.pause();
  }

  /// Resume background music.
  void resumeBackgroundMusic() {
    FlameAudio.bgm.resume();
  }

  /// Start ambient farm sounds (occasional chicken clucks).
  void startAmbientSounds() {
    if (_isAmbientActive || !_isMusicEnabled) return;
    _isAmbientActive = true;

    // Schedule random ambient chicken sounds
    _scheduleNextAmbientSound();
  }

  /// Stop ambient farm sounds.
  void stopAmbientSounds() {
    _isAmbientActive = false;
    _ambientChickenTimer?.cancel();
    _ambientChickenTimer = null;
  }

  /// Schedule the next ambient sound with random delay.
  void _scheduleNextAmbientSound() {
    if (!_isAmbientActive) return;

    // Random delay between 4-10 seconds
    final delay = 4000 + _random.nextInt(6000);

    _ambientChickenTimer = Timer(Duration(milliseconds: delay), () {
      if (_isAmbientActive) {
        _playAmbientChickenSound();
        _scheduleNextAmbientSound();
      }
    });
  }

  /// Play a quiet ambient chicken sound.
  void _playAmbientChickenSound() {
    final sounds = ['chicken.ogg', 'chickenv2.ogg', 'chickenv3.ogg'];
    final sound = sounds[_random.nextInt(sounds.length)];
    // Play at lower volume for ambient effect (reduced by 40%)
    FlameAudio.play(sound, volume: 0.15);
  }

  /// Play a random chicken sound (for state changes).
  void playChickenSound() {
    final sounds = ['chicken.ogg', 'chickenv2.ogg', 'chickenv3.ogg'];
    final sound = sounds[_random.nextInt(sounds.length)];
    // Reduced by 40% (0.6 -> 0.36)
    FlameAudio.play(sound, volume: 0.36);
  }

  /// Play fence placement sound.
  void playFenceSound() {
    FlameAudio.play('fence.ogg', volume: 0.7);
  }

  /// Play bell alarm sound.
  void playBellSound() {
    FlameAudio.play('bell.ogg', volume: 0.8);
  }

  /// Play success sound.
  void playSuccessSound() {
    FlameAudio.play('success.ogg', volume: 0.8);
  }

  /// Play fail sound.
  void playFailSound() {
    FlameAudio.play('fail.ogg', volume: 0.8);
  }

  /// Play tool placement sound (generic for all tools).
  void playToolPlacementSound() {
    FlameAudio.play('fence.ogg', volume: 0.7);
  }
}
