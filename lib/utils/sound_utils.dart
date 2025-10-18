import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class SoundUtils {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  /// Initialize the audio player
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set volume to a reasonable level (0.0 to 1.0)
      await _audioPlayer.setVolume(0.5);
      _isInitialized = true;
      if (kDebugMode) {
        print('SoundUtils initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SoundUtils: $e');
      }
    }
  }

  /// Play message sent sound
  static Future<void> playMessageSentSound() async {
    try {
      await initialize();

      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Try to load from assets first
      try {
        await _audioPlayer
            .setAsset('assets/audios/Sending-Message-Sound-Effect.mp3');
        await _audioPlayer.play();
        if (kDebugMode) {
          print('Message sent sound played from assets');
        }
      } catch (assetError) {
        // If asset not found, create a simple beep sound
        if (kDebugMode) {
          print('Asset not found, creating beep sound: $assetError');
        }
        await _createBeepSound();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing message sent sound: $e');
      }
      // Don't throw error to avoid breaking the message sending flow
    }
  }

  /// Create a simple beep sound programmatically
  static Future<void> _createBeepSound() async {
    try {
      // Generate a simple sine wave beep
      const sampleRate = 44100;
      const duration = 0.1; // 100ms
      const frequency = 800; // 800 Hz

      final samples = <double>[];
      for (int i = 0; i < (sampleRate * duration).round(); i++) {
        final t = i / sampleRate;
        final sample = sin(2 * pi * frequency * t);
        samples.add(sample);
      }

      // Convert to audio format (simplified approach)
      // For now, we'll just use a very short silence as fallback
      // In a real implementation, you'd convert the sine wave to proper audio format

      if (kDebugMode) {
        print('Beep sound generated (simulated)');
      }

      // Since we can't easily generate audio programmatically without complex libraries,
      // we'll just log that the sound would play
      // In a production app, you'd want to include actual sound files
    } catch (e) {
      if (kDebugMode) {
        print('Error creating beep sound: $e');
      }
    }
  }

  /// Play notification sound (for incoming messages)
  static Future<void> playNotificationSound() async {
    try {
      await initialize();

      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Try to load from assets first
      try {
        await _audioPlayer.setAsset('assets/audios/notification.mp3');
        await _audioPlayer.play();
        if (kDebugMode) {
          print('Notification sound played from assets');
        }
      } catch (assetError) {
        // If asset not found, create a simple notification sound
        if (kDebugMode) {
          print('Asset not found, creating notification sound: $assetError');
        }
        await _createNotificationSound();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing notification sound: $e');
      }
    }
  }

  /// Create a simple notification sound
  static Future<void> _createNotificationSound() async {
    try {
      if (kDebugMode) {
        print('Notification sound generated (simulated)');
      }
      // Similar to beep sound, but with different frequency
      // For now, just log the action
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification sound: $e');
      }
    }
  }

  /// Dispose the audio player
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      if (kDebugMode) {
        print('SoundUtils disposed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing SoundUtils: $e');
      }
    }
  }
}
