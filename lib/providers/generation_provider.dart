import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/app_record.dart';
import '../models/generation_state.dart';
import '../models/llm_config.dart';
import '../providers/history_provider.dart';
import '../services/build_fix_service.dart';
import '../services/build_service.dart';
import '../services/icon_generator.dart';
import '../services/project_generator.dart';

class GenerationProvider extends ChangeNotifier {
  GenerationState _state = const GenerationState();

  GenerationState get state => _state;

  bool get isGenerating =>
      _state.status == GenerationStatus.generating ||
      _state.status == GenerationStatus.writingFiles ||
      _state.status == GenerationStatus.building ||
      _state.status == GenerationStatus.fixing;

  void _addLog(String log) {
    _state = _state.copyWith(logs: [..._state.logs, log]);
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

  // ── Main entry point ─────────────────────────────────────────────────────────

  Future<void> generateApp({
    required String prompt,
    required String outputDir,
    required String appName,
    required String packageName,
    required LLMConfig llmConfig,
    HistoryProvider? historyProvider,
    bool autoBuild = true,
    int maxBuildAttempts = 3,
    String? customIconPath,
  }) async {
    _state = GenerationState(
      status: GenerationStatus.generating,
      statusMessage: 'Starting generation...',
      logs: const ['🚀 Starting Android app generation...'],
      progress: 0.0,
      maxBuildAttempts: maxBuildAttempts,
    );
    notifyListeners();

    // ── Phase 1-5: Code generation ──────────────────────────────────────────
    Map<String, String> files;
    try {
      final generator = ProjectGenerator(
        llmConfig: llmConfig,
        onLog: _addLog,
        onProgress: _setProgress,
      );

      files = await generator.generate(
        prompt: prompt,
        outputDir: outputDir,
        appName: appName,
        packageName: packageName,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: GenerationStatus.error,
        statusMessage: 'Generation failed',
        errorMessage: e.toString(),
      );
      _addLog('❌ Error: $e');
      notifyListeners();
      return;
    }

    // Generate and write app icon to mipmap directories
    try {
      _addLog('🎨 Generating app icon...');
      final iconMap = await IconGenerator.generateMipmapIcons(
        appName: appName,
        customIconPath: customIconPath,
      );
      await IconGenerator.writeIconsToDisk(outputDir, iconMap);
      final source = customIconPath != null ? 'custom icon' : 'auto-generated from "$appName"';
      _addLog('✅ App icon created ($source) — ${iconMap.length} densities');
    } catch (e) {
      _addLog('⚠️  Icon generation failed (using default): $e');
    }

    // Mark generation complete
    _state = _state.copyWith(
      status: autoBuild ? GenerationStatus.building : GenerationStatus.complete,
      statusMessage: autoBuild ? 'Building APK…' : 'Generation complete!',
      generatedFiles: files,
      outputPath: outputDir,
      progress: autoBuild ? 0.0 : 1.0,
    );
    notifyListeners();

    // ── Phases 6-7: Build + fix loop ────────────────────────────────────────
    String? apkPath;
    BuildStatus buildStatus = BuildStatus.notBuilt;
    int totalAttempts = 0;

    if (autoBuild) {
      final result = await _runBuildLoop(
        outputDir: outputDir,
        packageName: packageName,
        appName: appName,
        llmConfig: llmConfig,
        maxAttempts: maxBuildAttempts,
        currentFiles: files,
      );
      apkPath = result.apkPath;
      buildStatus = result.success ? BuildStatus.success : BuildStatus.failed;
      totalAttempts = _state.buildAttempt;
    }

    // ── Save to history ─────────────────────────────────────────────────────
    if (historyProvider != null) {
      final now = DateTime.now();
      // Re-read final files from disk so history has the fixed versions
      final finalFiles = _readFilesFromDisk(outputDir, files);
      final record = AppRecord(
        id: _generateId(),
        appName: appName,
        packageName: packageName,
        outputPath: outputDir,
        originalPrompt: prompt,
        files: finalFiles,
        createdAt: now,
        updatedAt: now,
        buildStatus: buildStatus,
        apkPath: apkPath,
        buildAttempts: totalAttempts,
      );
      await historyProvider.addRecord(record);
    }
  }

  // ── Build + fix loop ─────────────────────────────────────────────────────────

  Future<BuildResult> _runBuildLoop({
    required String outputDir,
    required String packageName,
    required String appName,
    required LLMConfig llmConfig,
    required int maxAttempts,
    required Map<String, String> currentFiles,
  }) async {
    // Mutable copy — updated as fixes are applied
    var liveFiles = Map<String, String>.from(currentFiles);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _state = _state.copyWith(
        status: GenerationStatus.building,
        statusMessage: 'Building APK (attempt $attempt/$maxAttempts)…',
        buildAttempt: attempt,
        progress: 0.0,
      );
      notifyListeners();

      _addLog('');
      _addLog('══════════════════════════════════════════');
      _addLog('🔨 BUILD — Attempt $attempt / $maxAttempts');
      _addLog('══════════════════════════════════════════');

      final buildService = BuildService(onLine: _addLog);
      final result = await buildService.runBuild(outputDir);

      if (result.success) {
        _state = _state.copyWith(
          status: GenerationStatus.buildSuccess,
          statusMessage: '✅ APK built successfully!',
          apkPath: result.apkPath,
          buildErrors: const [],
          progress: 1.0,
        );
        notifyListeners();

        // Open APK folder in Windows Explorer
        if (result.apkPath != null) {
          _openFolder(result.apkPath!);
        }

        return result;
      }

      // Build failed
      final errorLines =
          result.errors.map((e) => e.toString()).toList();

      _state = _state.copyWith(
        buildErrors: errorLines,
      );
      notifyListeners();

      if (attempt == maxAttempts) {
        // Gave up
        _addLog('');
        _addLog('❌ Build failed after $maxAttempts attempt(s). Giving up.');
        _state = _state.copyWith(
          status: GenerationStatus.buildFailed,
          statusMessage: 'Build failed after $maxAttempts attempts',
          progress: 1.0,
        );
        notifyListeners();
        return result;
      }

      // ── Fix phase ────────────────────────────────────────────────────────
      _state = _state.copyWith(
        status: GenerationStatus.fixing,
        statusMessage: 'Fixing errors (attempt $attempt/$maxAttempts)…',
      );
      notifyListeners();

      final fixer = BuildFixService(
        llmConfig: llmConfig,
        onLog: _addLog,
      );

      final fixedFiles = await fixer.fix(
        errors: result.errors,
        allFiles: liveFiles,
        projectPath: outputDir,
        packageName: packageName,
        appName: appName,
        attempt: attempt,
        maxAttempts: maxAttempts,
      );

      // Write fixed files to disk and update live map
      final packagePath = packageName.replaceAll('.', '/');
      for (final entry in fixedFiles.entries) {
        String filePath = entry.key;
        // Only filename returned → normalise to full relative path
        if (!filePath.contains('/') && !filePath.startsWith('app/')) {
          filePath = 'app/src/main/java/$packagePath/$filePath';
        }
        if (!filePath.endsWith('.kt')) filePath = '$filePath.kt';

        final absFile = File(p.join(outputDir, filePath));
        await absFile.parent.create(recursive: true);
        await absFile.writeAsString(entry.value);
        liveFiles[filePath] = entry.value;
        _addLog('  🔧 Fixed: $filePath');
      }
    }

    // Should not reach here, but return a failed result
    return const BuildResult(success: false, outputLines: [], errors: []);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Re-read all .kt files from disk to capture any LLM-fixed versions.
  Map<String, String> _readFilesFromDisk(
      String outputDir, Map<String, String> original) {
    final result = Map<String, String>.from(original);
    final dir = Directory(outputDir);
    if (!dir.existsSync()) return result;
    try {
      for (final file in dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt'))) {
        final rel = p
            .relative(file.path, from: outputDir)
            .replaceAll('\\', '/');
        result[rel] = file.readAsStringSync();
      }
    } catch (_) {}
    return result;
  }

  /// Simple unique id: timestamp + 6 random hex chars.
  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final rnd =
        Random.secure().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$ts-$rnd';
  }

  /// Opens the folder containing [apkPath] in Windows Explorer,
  /// with the APK file selected.
  Future<void> _openFolder(String apkPath) async {
    try {
      // Normalize to backslashes for Windows Explorer
      final winPath = apkPath.replaceAll('/', '\\');
      // explorer.exe /select, requires the path immediately after the comma
      // Using Process.run with runInShell avoids argument-splitting issues
      await Process.run(
        'explorer.exe',
        ['/select,"$winPath"'],
        runInShell: true,
      );
      // explorer.exe always returns exit code 1, even on success
      _addLog('📂 Opened APK folder: $apkPath');
    } catch (e) {
      _addLog('⚠️  Could not open APK folder: $e');
    }
  }
}
