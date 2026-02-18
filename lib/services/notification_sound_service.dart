import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationSoundService {
  NotificationSoundService._();
  static final NotificationSoundService instance = NotificationSoundService._();

  bool _initialized = false;
  DateTime? _lastPlayedAt;
  Set<String>? _assetManifestKeys;
  AudioPlayer? _audioPlayer;
  bool _audioConfigured = false;

  Future<void> init() async {
    if (_initialized) return;
    // Skip audio on desktop/web to avoid MissingPlugin on some builds.
    if (!(Platform.isAndroid || Platform.isIOS)) {
      _initialized = true;
      return;
    }
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      _audioConfigured = true;
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
    _initialized = true;
  }

  Future<void> playNewOrderAlarm({
    Duration minInterval = const Duration(seconds: 2),
  }) async {
    await init();

    final now = DateTime.now();
    final last = _lastPlayedAt;
    if (last != null && now.difference(last) < minInterval) {
      return;
    }

    // Essaye les assets si dispo (mobile), sinon passe à l'alerte système.
    final played = await _playAssetFallbackChain();
    if (!played) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
    _lastPlayedAt = now;
  }

  Future<bool> _playAssetFallbackChain() async {
    // Priorité au son principal fourni dans assets/audio/order-notification.mp3
    const candidates = [
      'audio/order-notification.mp3',
      'audio/order_alarm.mp3',
      'audio/alert.mp3',
    ];

    for (final assetPath in candidates) {
      final exists = await _assetExists(assetPath);
      if (!exists) continue;
      try {
        if (_audioConfigured && _audioPlayer != null) {
          await _audioPlayer!.stop();
          await _audioPlayer!.play(AssetSource(assetPath));
          return true;
        }
      } catch (e) {
        debugPrint('Order alarm asset playback failed for $assetPath: $e');
      }
    }
    return false;
  }

  Future<bool> _assetExists(String relativeAssetPath) async {
    final key = 'assets/$relativeAssetPath';
    final keys = await _manifestKeys();
    if (keys != null) {
      return keys.contains(key);
    }

    try {
      await rootBundle.load(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>?> _manifestKeys() async {
    final cached = _assetManifestKeys;
    if (cached != null) return cached;

    try {
      final jsonText = await rootBundle.loadString('AssetManifest.json');
      if (jsonText.trim().isEmpty) return null;
      final decoded = json.decode(jsonText);
      if (decoded is! Map) return null;
      final keys = decoded.keys
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toSet();
      _assetManifestKeys = keys;
      return keys;
    } catch (_) {
      return null;
    }
  }
}
