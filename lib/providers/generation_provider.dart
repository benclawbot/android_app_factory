import 'dart:math';

import 'package:flutter/material.dart';
import '../models/app_record.dart';
import '../models/generation_state.dart';
import '../models/llm_config.dart';
import '../providers/history_provider.dart';
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
    HistoryProvider? historyProvider,
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

      // Save to history
      if (historyProvider != null) {
        final now = DateTime.now();
        final record = AppRecord(
          id: _generateId(),
          appName: appName,
          packageName: packageName,
          outputPath: outputDir,
          originalPrompt: prompt,
          files: files,
          createdAt: now,
          updatedAt: now,
        );
        await historyProvider.addRecord(record);
      }
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

  /// Simple unique id: timestamp + 6 random hex chars.
  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final rnd = Random.secure()
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return '$ts-$rnd';
  }
}
