enum GenerationStatus {
  idle,
  generating,
  writingFiles,
  complete,
  error,
}

class GenerationState {
  final GenerationStatus status;
  final String statusMessage;
  final List<String> logs;
  final double progress;
  final String? outputPath;
  final String? errorMessage;
  final Map<String, String> generatedFiles;

  const GenerationState({
    this.status = GenerationStatus.idle,
    this.statusMessage = '',
    this.logs = const [],
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
    this.generatedFiles = const {},
  });

  GenerationState copyWith({
    GenerationStatus? status,
    String? statusMessage,
    List<String>? logs,
    double? progress,
    String? outputPath,
    String? errorMessage,
    Map<String, String>? generatedFiles,
  }) {
    return GenerationState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      logs: logs ?? this.logs,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedFiles: generatedFiles ?? this.generatedFiles,
    );
  }
}
