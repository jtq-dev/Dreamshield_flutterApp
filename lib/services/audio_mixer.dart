import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Three-channel noise mixer using **bundled assets** (no CORS).
class AudioMixer {
  final AudioPlayer _pink = AudioPlayer();
  final AudioPlayer _brown = AudioPlayer();
  final AudioPlayer _white = AudioPlayer();

  bool _inited = false;

  Future<void> _configureSession() async {
    // audio_session is a no-op on web; safe everywhere.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> init() async {
    if (_inited) return;
    await _configureSession();
    try {
      // Use local assets so web & mobile both work without remote URLs.
      await _pink.setAsset('assets/audio/pink.mp3');
      await _brown.setAsset('assets/audio/brown.mp3');
      await _white.setAsset('assets/audio/white.mp3');
      await _pink.setLoopMode(LoopMode.all);
      await _brown.setLoopMode(LoopMode.all);
      await _white.setLoopMode(LoopMode.all);
      _inited = true;
    } on PlayerException catch (e) {
      throw Exception('Audio init failed (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Audio init failed: $e');
    }
  }

  Future<void> start({double pink = 0.5, double brown = 0.3, double white = 0.2}) async {
    await init();
    try {
      await _pink.setVolume(pink);
      await _brown.setVolume(brown);
      await _white.setVolume(white);
      // On web, a user gesture is required. Our Play button is a gesture, so this is fine.
      await Future.wait([_pink.play(), _brown.play(), _white.play()]);
    } on PlayerException catch (e) {
      throw Exception('Playback failed (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Playback failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await Future.wait([_pink.stop(), _brown.stop(), _white.stop()]);
    } catch (_) {}
  }

  Future<void> setVolumes(double pink, double brown, double white) async {
    try {
      await _pink.setVolume(pink);
      await _brown.setVolume(brown);
      await _white.setVolume(white);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _pink.dispose();
    await _brown.dispose();
    await _white.dispose();
  }
}
