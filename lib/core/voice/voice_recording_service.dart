import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract class VoiceRecordingService {
  Future<bool> hasPermission();
  Future<String> start();
  Future<String?> stop();
  Future<bool> isRecording();
  Future<void> dispose();
}

class RecordVoiceRecordingService implements VoiceRecordingService {
  RecordVoiceRecordingService({
    AudioRecorder? recorder,
  }) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentPath;

  @override
  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<String> start() async {
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/senior-companion-request-${DateTime.now().microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _currentPath = path;
    return path;
  }

  @override
  Future<String?> stop() async {
    final path = await _recorder.stop();
    final fallbackPath = _currentPath;
    _currentPath = null;
    return path ?? fallbackPath;
  }

  @override
  Future<bool> isRecording() {
    return _recorder.isRecording();
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }
}
