import 'package:just_audio/just_audio.dart';

abstract class VoicePlaybackService {
  Future<void> playFile(String path);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioVoicePlaybackService implements VoicePlaybackService {
  JustAudioVoicePlaybackService({
    AudioPlayer? player,
  }) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> stop() {
    return _player.stop();
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}
