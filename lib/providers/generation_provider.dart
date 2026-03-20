import 'package:flutter/material.dart';
import '../models/generation_state.dart';
import '../models/llm_config.dart';
import '../services/project_generator.dart';

class GenerationProvider extends ChangeNotifier {
  GenerationState _state = const GenerationState();

  GenerationState get state => _state;

  bool get isGenerating => _state.status == GenerationStatus.generating ||
      _state.status == GenerationStatus.writingFiles;

  void _addLog(String log) {
    _state = _state.copyWith(
      logs: [..._state.logs, log],
    );
    notifyListeners();
  }

  void _setProgress(double progress) {
    _state = _state.copyWith(progress: progress);
    notifyListeners();
  }

  void reset() {
    _state = const GenerationState();
    notifyListeners();
  }

  Future<void> generateApp({
    required String prompt,
    required String outputDir,
    required String appName,
    required String packageName,
    required LLMConfig llmConfig,
  }) async {
    _state = const GenerationState(
      status: GenerationStatus.generating,
      statusMessage: 'Starting generation...',
      logs: ['🚀 Starting Android app generation...'],
      progress: 0.0,
    );
    notifyListeners();

    try {
      final generator = ProjectGenerator(
        llmConfig: llmConfig,
        onLog: _addLog,
        onProgress: _setProgress,
      );

      final files = await generator.generate(
        prompt: prompt,
        outputDir: outputDir,
        appName: appName,
        packageName: packageName,
      );

      _state = _state.copyWith(
        status: GenerationStatus.complete,
        statusMessage: 'Generation complete!',
        generatedFiles: files,
        outputPath: outputDir,
        progress: 1.0,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: GenerationStatus.error,
        statusMessage: 'Generation failed',
        errorMessage: e.toString(),
      );
      _addLog('❌ Error: $e');
      notifyListeners();
    }
  }
}
