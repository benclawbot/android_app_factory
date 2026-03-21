import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/app_record.dart';
import '../models/llm_config.dart';
import '../services/llm_service.dart';

enum UpdateMode {
  /// Only regenerate files that need to change.
  smartPatch,

  /// Regenerate all Kotlin source files from scratch.
  fullRegeneration,
}

/// Applies an LLM-driven update to an existing [AppRecord].
///
/// Call [update] to get back a new [AppRecord] with the patched files already
/// written to disk. The caller is responsible for persisting the new record via
/// [HistoryProvider.updateRecord].
class AppUpdater {
  final LLMConfig llmConfig;
  final void Function(String log) onLog;
  final void Function(double progress) onProgress;

  AppUpdater({
    required this.llmConfig,
    required this.onLog,
    required this.onProgress,
  });

  /// Run the update and return an updated [AppRecord].
  Future<AppRecord> update({
    required AppRecord record,
    required String updatePrompt,
    UpdateMode mode = UpdateMode.smartPatch,
  }) async {
    final llm = LLMService(llmConfig);
    try {
      onLog('🔍 Preparing update for "${record.appName}"...');
      onProgress(0.05);

      late Map<String, String> changedFiles;

      if (mode == UpdateMode.smartPatch) {
        changedFiles = await _smartPatch(llm, record, updatePrompt);
      } else {
        changedFiles = await _fullRegeneration(llm, record, updatePrompt);
      }

      if (changedFiles.isEmpty) {
        onLog('⚠️  LLM returned no changed files. Nothing to update.');
        return record;
      }

      onLog('📝 ${changedFiles.length} file(s) to update.');
      onProgress(0.80);

      // Write changed files to disk
      final packagePath = record.packageName.replaceAll('.', '/');
      final updatedFiles = Map<String, String>.from(record.files);

      for (final entry in changedFiles.entries) {
        String filePath = entry.key;
        if (!filePath.startsWith('app/src/main/java/')) {
          filePath = 'app/src/main/java/$packagePath/$filePath';
        }
        if (!filePath.endsWith('.kt')) filePath = '$filePath.kt';

        final file = File(p.join(record.outputPath, filePath));
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
        onLog('  📄 $filePath');

        updatedFiles[filePath] = entry.value;
      }

      onProgress(1.0);
      onLog('');
      onLog('🎉 Update applied — ${changedFiles.length} file(s) changed.');

      final now = DateTime.now();
      return record.copyWith(
        files: updatedFiles,
        updatedAt: now,
        updates: [
          ...record.updates,
          UpdateEntry(
            prompt: updatePrompt,
            timestamp: now,
            modifiedFiles: changedFiles.keys.toList(),
          ),
        ],
      );
    } finally {
      llm.dispose();
    }
  }

  // ── Smart patch ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> _smartPatch(
    LLMService llm,
    AppRecord record,
    String updatePrompt,
  ) async {
    onLog('🧠 Analyzing which files need to change...');
    onProgress(0.15);

    final existingCode = _buildExistingCodeBlock(record);
    final prompt = '''
You are modifying an existing Android Kotlin/Jetpack Compose app.

EXISTING APP
App Name: ${record.appName}
Package: ${record.packageName}
Original description: ${record.originalPrompt}

EXISTING SOURCE FILES
$existingCode

UPDATE REQUEST
$updatePrompt

OUTPUT ONLY THE FILES THAT NEED TO CHANGE (or new files to add).
Do NOT re-output files that are already correct and need no changes.
Keep the same package name: ${record.packageName}

Use the exact format:
```kotlin
// File: FileName.kt
<full updated file content>
```

Ensure every output file compiles — include all imports and the package declaration.
''';

    onLog('⚡ Requesting targeted patch from LLM...');
    onProgress(0.35);

    final response = await llm.generate(prompt, systemPrompt: _updateSystemPrompt);
    onProgress(0.70);

    return _parseFiles(response);
  }

  // ── Full regeneration ────────────────────────────────────────────────────────

  Future<Map<String, String>> _fullRegeneration(
    LLMService llm,
    AppRecord record,
    String updatePrompt,
  ) async {
    onLog('🔄 Full regeneration requested...');
    onProgress(0.15);

    final combinedPrompt = '''
${record.originalPrompt}

MODIFICATIONS TO APPLY:
$updatePrompt
''';

    final planPrompt = '''
I want to update an Android app. Plan the updated architecture:

App Description: $combinedPrompt
App Name: ${record.appName}
Package: ${record.packageName}

Provide a brief plan with screens, navigation, and key changes.
Keep it concise — just the plan, no code yet.
''';

    onLog('🧠 Re-planning app architecture...');
    final plan = await llm.generate(planPrompt, systemPrompt: _updateSystemPrompt);
    onProgress(0.35);

    final codePrompt = '''
Generate the COMPLETE updated Android app code.

App Description: $combinedPrompt
App Name: ${record.appName}
Package: ${record.packageName}

Architecture Plan:
$plan

Generate ALL Kotlin files. Format each file as:
```kotlin
// File: FileName.kt
<complete code>
```
''';

    onLog('⚡ Regenerating all source files...');
    final response = await llm.generate(codePrompt, systemPrompt: _codeSystemPrompt);
    onProgress(0.75);

    return _parseFiles(response);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Build a block of all .kt source file contents for the LLM context.
  String _buildExistingCodeBlock(AppRecord record) {
    final buffer = StringBuffer();
    final ktFiles = record.files.entries
        .where((e) => e.key.endsWith('.kt'))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in ktFiles) {
      // Use just the filename in the header for brevity
      final name = p.basename(entry.key);
      buffer.writeln('// File: $name');
      buffer.writeln(entry.value);
      buffer.writeln();
    }
    return buffer.toString();
  }

  Map<String, String> _parseFiles(String response) {
    final files = <String, String>{};

    // Primary: ```kotlin\n// File: Name.kt\n<content>```
    final primary = RegExp(
      r'```(?:kotlin|kt)?\s*\n?\/\/\s*(?:File:\s*)?(.+?\.kt)\s*\n([\s\S]*?)```',
      multiLine: true,
    );
    for (final m in primary.allMatches(response)) {
      files[m.group(1)!.trim()] = m.group(2)!.trim();
    }

    // Fallback: --- FILE: Name.kt ---
    if (files.isEmpty) {
      final alt = RegExp(
        r'---\s*FILE:\s*(.+?\.kt)\s*---\s*\n```(?:kotlin|kt)?\s*\n([\s\S]*?)```',
        multiLine: true,
      );
      for (final m in alt.allMatches(response)) {
        files[m.group(1)!.trim()] = m.group(2)!.trim();
      }
    }

    return files;
  }

  static const _updateSystemPrompt = '''
You are an expert Android developer specializing in Kotlin and Jetpack Compose.
You are modifying an existing app. Follow the user's instructions precisely.
Always output complete, compilable Kotlin files with all necessary imports.
Format: ```kotlin\n// File: FileName.kt\n<code>\n```
''';

  static const _codeSystemPrompt = '''
You are an expert Android developer. Generate COMPLETE, COMPILABLE Kotlin/Jetpack Compose code.
1. Every file MUST start with the correct package declaration
2. Every file MUST include ALL necessary imports
3. Use Jetpack Compose with Material 3
4. Use NavHost + NavController for navigation
5. Format each file as: ```kotlin\n// File: FileName.kt\n<code>\n```
''';
}
