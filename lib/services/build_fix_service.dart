import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/llm_config.dart';
import '../services/build_service.dart';
import '../services/llm_service.dart';

/// Takes a list of [BuildError]s + the current file map, sends the broken
/// files to the LLM with the error context, and returns a map of
/// `relativePath → fixedContent` for only the files that were changed.
class BuildFixService {
  final LLMConfig llmConfig;
  final void Function(String log) onLog;

  BuildFixService({required this.llmConfig, required this.onLog});

  /// Ask the LLM to fix [errors].
  ///
  /// [projectPath] is the absolute project root (used to read current file
  /// content from disk).
  /// [allFiles] is the in-memory map of all known files (path → content).
  /// [packageName] and [appName] are passed for context.
  /// [attempt] is the 1-based attempt number shown in the log.
  ///
  /// Returns a map of `relativePath → fixedContent` (only changed files).
  Future<Map<String, String>> fix({
    required List<BuildError> errors,
    required Map<String, String> allFiles,
    required String projectPath,
    required String packageName,
    required String appName,
    required int attempt,
    required int maxAttempts,
  }) async {
    onLog('');
    onLog('🔧 Attempt $attempt/$maxAttempts — sending ${errors.length} error(s) to LLM for fixing...');

    // Collect unique files that have errors
    final brokenRelPaths = errors.map((e) => e.relativePath).toSet();
    final brokenFiles = <String, String>{};

    for (final rel in brokenRelPaths) {
      // Prefer in-memory content; fall back to disk
      if (allFiles.containsKey(rel)) {
        brokenFiles[rel] = allFiles[rel]!;
      } else {
        // Try to read from disk with normalised separators
        final absPath = p.join(projectPath, rel);
        final f = File(absPath);
        if (f.existsSync()) {
          brokenFiles[rel] = f.readAsStringSync();
        }
      }
    }

    onLog('📂 Files with errors: ${brokenFiles.keys.map(p.basename).join(', ')}');

    final prompt = _buildPrompt(
      errors: errors,
      brokenFiles: brokenFiles,
      packageName: packageName,
      appName: appName,
      attempt: attempt,
      maxAttempts: maxAttempts,
    );

    final llm = LLMService(llmConfig);
    try {
      onLog('⚡ Waiting for LLM fix...');
      final response = await llm.generate(prompt, systemPrompt: _systemPrompt);
      final fixed = _parseFiles(response);

      if (fixed.isEmpty) {
        onLog('⚠️  LLM returned no files — will retry build as-is.');
      } else {
        onLog('✅ LLM returned ${fixed.length} fixed file(s).');
      }

      return fixed;
    } finally {
      llm.dispose();
    }
  }

  // ── Prompt construction ──────────────────────────────────────────────────────

  String _buildPrompt({
    required List<BuildError> errors,
    required Map<String, String> brokenFiles,
    required String packageName,
    required String appName,
    required int attempt,
    required int maxAttempts,
  }) {
    final buf = StringBuffer();

    buf.writeln('Fix the following Kotlin compilation errors in an Android '
        'Jetpack Compose project.');
    buf.writeln('App: $appName  |  Package: $packageName  |  '
        'Fix attempt: $attempt of $maxAttempts');
    buf.writeln();

    // Error list — grouped by file
    buf.writeln('═══ COMPILATION ERRORS ═══');
    final byFile = <String, List<BuildError>>{};
    for (final e in errors) {
      byFile.putIfAbsent(e.fileName, () => []).add(e);
    }
    for (final entry in byFile.entries) {
      buf.writeln('File: ${entry.key}');
      for (final e in entry.value) {
        buf.writeln('  Line ${e.line}:${e.column}  ${e.message}');
      }
    }

    buf.writeln();
    buf.writeln('═══ SOURCE FILES WITH ERRORS ═══');
    buf.writeln('(Only files that have at least one error are shown.)');
    buf.writeln();

    for (final entry in brokenFiles.entries) {
      final name = p.basename(entry.key);
      buf.writeln('// File: $name');
      buf.writeln(entry.value);
      buf.writeln();
    }

    buf.writeln('═══ INSTRUCTIONS ═══');
    buf.writeln('1. Fix EVERY error listed above.');
    buf.writeln(
        '2. Output ONLY the files you modified — do not re-output unchanged files.');
    buf.writeln('3. For each fixed file use this exact format:');
    buf.writeln('```kotlin');
    buf.writeln('// File: FileName.kt');
    buf.writeln('<complete corrected file content>');
    buf.writeln('```');
    buf.writeln('4. Every output file MUST have:');
    buf.writeln('   - Correct package declaration: package $packageName');
    buf.writeln('   - All necessary imports');
    buf.writeln('   - No external libraries outside Jetpack Compose + Material 3 + Navigation');

    return buf.toString();
  }

  // ── Response parsing ─────────────────────────────────────────────────────────

  Map<String, String> _parseFiles(String response) {
    final files = <String, String>{};

    // Primary: ```kotlin\n// File: Name.kt\n<content>```
    final primary = RegExp(
      r'```(?:kotlin|kt)?\s*\n?\/\/\s*(?:File:\s*)?(.+?\.kt)\s*\n([\s\S]*?)```',
      multiLine: true,
    );
    for (final m in primary.allMatches(response)) {
      final name = m.group(1)!.trim();
      final content = m.group(2)!.trim();
      if (content.isNotEmpty) files[name] = content;
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

  static const _systemPrompt = '''
You are an expert Android developer specializing in Kotlin and Jetpack Compose.
Your task is to fix compilation errors in an existing Android project.

Rules:
- Fix every error listed — do not leave any unresolved references or type mismatches.
- Always include the full corrected file (not just the changed lines).
- Always include the package declaration and ALL necessary imports.
- Do NOT use any library that is not part of Jetpack Compose + Material 3 + AndroidX Navigation.
- Output format: ```kotlin\\n// File: FileName.kt\\n<full content>\\n```
- Output ONLY files that need to change. Do not output files that already compile.
''';
}
