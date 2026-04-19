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
  });

  final String audioFilePath;
}

class VoiceInteractionResult {
  const VoiceInteractionResult({
    required this.responseAudioPath,
  });

  final String responseAudioPath;
}
