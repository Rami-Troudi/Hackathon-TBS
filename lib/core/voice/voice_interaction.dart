enum VoiceAudience {
  senior,
  guardian,
}

enum VoiceInteractionStatus {
  idle,
  listening,
  processing,
  playing,
  unavailable,
  error,
}

class VoiceGatewayAudioResponse {
  const VoiceGatewayAudioResponse({
    required this.audioFilePath,
    this.responseText,
  });

  final String audioFilePath;
  final String? responseText;
}

class VoiceInteractionResult {
  const VoiceInteractionResult({
    required this.responseAudioPath,
    this.responseText,
  });

  final String responseAudioPath;
  final String? responseText;
}
