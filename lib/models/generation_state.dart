enum GenerationStatus {
  idle,
  generating,
  writingFiles,
  complete,      // code written, no build requested
  building,      // Gradle running
  fixing,        // LLM fixing compiler errors
  buildSuccess,  // APK produced
  buildFailed,   // gave up after maxAttempts
  error,         // fatal error in generation
}

class GenerationState {
  final GenerationStatus status;
  final String statusMessage;
  final List<String> logs;
  final double progress;
  final String? outputPath;
  final String? errorMessage;
  final Map<String, String> generatedFiles;

  // Build phase fields
  final int buildAttempt;
  final int maxBuildAttempts;
  final String? apkPath;
  final List<String> buildErrors;

  const GenerationState({
    this.status = GenerationStatus.idle,
    this.statusMessage = '',
    this.logs = const [],
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
    this.generatedFiles = const {},
    this.buildAttempt = 0,
    this.maxBuildAttempts = 10,
    this.apkPath,
    this.buildErrors = const [],
  });

  GenerationState copyWith({
    GenerationStatus? status,
    String? statusMessage,
    List<String>? logs,
    double? progress,
    String? outputPath,
    String? errorMessage,
    Map<String, String>? generatedFiles,
    int? buildAttempt,
    int? maxBuildAttempts,
    String? apkPath,
    List<String>? buildErrors,
  }) {
    return GenerationState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      logs: logs ?? this.logs,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedFiles: generatedFiles ?? this.generatedFiles,
      buildAttempt: buildAttempt ?? this.buildAttempt,
      maxBuildAttempts: maxBuildAttempts ?? this.maxBuildAttempts,
      apkPath: apkPath ?? this.apkPath,
      buildErrors: buildErrors ?? this.buildErrors,
    );
  }
}
