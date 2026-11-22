import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../models/llm_config.dart';
import 'generated_path_guard.dart';
import '../services/llm_service.dart';
import '../templates/android_templates.dart';

class ProjectGenerator {
  final LLMConfig llmConfig;
  final void Function(String log) onLog;
  final void Function(double progress) onProgress;

  ProjectGenerator({
    required this.llmConfig,
    required this.onLog,
    required this.onProgress,
  });

  Future<Map<String, String>> generate({
    required String prompt,
    required String outputDir,
    required String appName,
    required String packageName,
  }) async {
    final generatedFiles = <String, String>{};
    final llm = LLMService(llmConfig);

    try {
      // Step 1: Plan the app structure
      onLog('🧠 Analyzing prompt and planning app structure...');
      onProgress(0.05);

      final planPrompt = _buildPlanPrompt(prompt, appName, packageName);
      final plan = await llm.generate(planPrompt, systemPrompt: _systemPrompt);

      onLog('📋 App plan generated.');
      onLog(plan.length > 300 ? '${plan.substring(0, 300)}...' : plan);
      onProgress(0.15);

      // Step 2: Generate the actual Kotlin code
      onLog('⚡ Generating Kotlin/Jetpack Compose code...');

      final codePrompt = _buildCodePrompt(prompt, appName, packageName, plan);
      final codeResponse = await llm.generate(codePrompt, systemPrompt: _codeSystemPrompt);

      onLog('✅ Code generated. Parsing files...');
      onProgress(0.60);

      // Step 3: Parse the LLM response into files
      final parsedFiles = _parseGeneratedFiles(codeResponse);
      onLog('📂 Parsed ${parsedFiles.length} files from LLM response.');
      onProgress(0.70);

      // Step 4: Build the project scaffold
      onLog('🏗️ Creating Android Studio project structure...');

      final packagePath = packageName.replaceAll('.', '/');
      final templates = AndroidTemplates(
        appName: appName,
        packageName: packageName,
      );

      // Static template files
      generatedFiles['build.gradle.kts'] = templates.rootBuildGradle;
      generatedFiles['app/build.gradle.kts'] = templates.appBuildGradle;
      generatedFiles['settings.gradle.kts'] = templates.settingsGradle;
      generatedFiles['gradle.properties'] = templates.gradleProperties;
      generatedFiles['gradle/wrapper/gradle-wrapper.properties'] = templates.gradleWrapperProperties;
      generatedFiles['gradle/libs.versions.toml'] = templates.libsVersionsToml;
      generatedFiles['app/src/main/AndroidManifest.xml'] = templates.androidManifest;
      generatedFiles['app/src/main/res/values/strings.xml'] = templates.stringsXml;
      generatedFiles['app/src/main/res/values/themes.xml'] = templates.themesXml;

      onProgress(0.80);

      // Model-supplied filenames must be validated before reaching the filesystem.
      for (final entry in parsedFiles.entries) {
        final filePath = safeGeneratedKotlinPath(entry.key, packagePath);
        generatedFiles[filePath] = entry.value;
      }

      // If no MainActivity was generated, add the default one
      final mainActivityPath = 'app/src/main/java/$packagePath/MainActivity.kt';
      if (!generatedFiles.containsKey(mainActivityPath)) {
        generatedFiles[mainActivityPath] = templates.mainActivityFallback;
      }

      onProgress(0.90);

      // Step 5: Write files to disk
      onLog('💾 Writing ${generatedFiles.length} files to disk...');

      final output = Directory(outputDir);
      await output.create(recursive: true);
      final resolvedRoot = await output.resolveSymbolicLinks();
      for (final entry in generatedFiles.entries) {
        final file = File(safeGeneratedOutputPath(resolvedRoot, entry.key));
        await file.parent.create(recursive: true);
        // Refuse an existing symlinked directory that escapes the output root.
        final realParent = await file.parent.resolveSymbolicLinks();
        if (!p.isWithin(resolvedRoot, realParent) && !p.equals(resolvedRoot, realParent)) {
          throw FormatException('Generated output escapes project folder');
        }
        await file.writeAsString(entry.value);
        onLog('  📄 ' + entry.key);
      }

      // Write gradlew (needed to build)
      await _writeGradleWrapper(outputDir);

      onProgress(1.0);
      onLog('');
      onLog('🎉 Project generated successfully!');
      onLog('📁 Output: $outputDir');
      onLog('');
      onLog('To open: Open Android Studio → File → Open → Select the folder');

      return generatedFiles;
    } catch (e) {
      onLog('❌ Error: $e');
      rethrow;
    } finally {
      llm.dispose();
    }
  }

  Map<String, String> _parseGeneratedFiles(String response) {
    final files = <String, String>{};
    // Parse ```filename.kt ... ``` blocks
    final regex = RegExp(
      r'```(?:kotlin|kt)?\s*\n?\/\/\s*(?:File:\s*)?(.+?\.kt)\s*\n([\s\S]*?)```',
      multiLine: true,
    );

    for (final match in regex.allMatches(response)) {
      final filename = match.group(1)!.trim();
      final content = match.group(2)!.trim();
      files[filename] = content;
    }

    // Also try the --- FILE: path --- format
    if (files.isEmpty) {
      final altRegex = RegExp(
        r'---\s*FILE:\s*(.+?\.kt)\s*---\s*\n```(?:kotlin|kt)?\s*\n([\s\S]*?)```',
        multiLine: true,
      );
      for (final match in altRegex.allMatches(response)) {
        final filename = match.group(1)!.trim();
        final content = match.group(2)!.trim();
        files[filename] = content;
      }
    }

    // Last resort: try any code block with a package declaration
    if (files.isEmpty) {
      final codeBlockRegex = RegExp(
        r'```(?:kotlin|kt)?\s*\n([\s\S]*?)```',
        multiLine: true,
      );
      int index = 0;
      for (final match in codeBlockRegex.allMatches(response)) {
        final content = match.group(1)!.trim();
        if (content.contains('package ') || content.contains('import ')) {
          // Try to extract class name
          final classMatch = RegExp(r'class\s+(\w+)').firstMatch(content);
          final name = classMatch?.group(1) ?? 'GeneratedFile$index';
          files['$name.kt'] = content;
          index++;
        }
      }
    }

    return files;
  }

  Future<void> _writeGradleWrapper(String outputDir) async {
    // Write a minimal gradlew.bat for Windows
    final gradlewBat = File(p.join(outputDir, 'gradlew.bat'));
    await gradlewBat.writeAsString(AndroidTemplates.gradlewBat);
    // Write gradlew for Linux/Mac
    final gradlew = File(p.join(outputDir, 'gradlew'));
    await gradlew.writeAsString(AndroidTemplates.gradlewSh);

    // Copy gradle-wrapper.jar so gradlew actually works
    await _copyGradleWrapperJar(outputDir);
  }

  /// Copies the bundled gradle-wrapper.jar from Flutter assets into the
  /// generated project's gradle/wrapper/ directory.
  Future<void> _copyGradleWrapperJar(String outputDir) async {
    final destDir = Directory(p.join(outputDir, 'gradle', 'wrapper'));
    await destDir.create(recursive: true);
    final destJar = File(p.join(destDir.path, 'gradle-wrapper.jar'));

    if (destJar.existsSync()) return; // already there

    try {
      final byteData = await rootBundle.load('assets/gradle/gradle-wrapper.jar');
      await destJar.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      onLog('  📎 gradle-wrapper.jar copied from bundled assets');
    } catch (e) {
      onLog('  ⚠️  Could not copy gradle-wrapper.jar: $e');
    }
  }

  String get _systemPrompt => '''
You are an expert Android developer specializing in modern Kotlin and Jetpack Compose.
You generate clean, production-ready Android app code.
You always use:
- Kotlin (never Java)
- Jetpack Compose for UI (never XML layouts)
- Material 3 design
- NavHost/NavController for multi-screen navigation
- ViewModel + State for state management
- Clean architecture patterns

When generating code, output each file in this format:
```kotlin
// File: FileName.kt
<full file content>
```

Always include the package declaration and all necessary imports in each file.
''';

  String get _codeSystemPrompt => '''
You are an expert Android developer. Generate COMPLETE, COMPILABLE Kotlin/Jetpack Compose code.

RULES:
1. Every file MUST start with the correct package declaration
2. Every file MUST include ALL necessary imports
3. Use Jetpack Compose with Material 3
4. Use NavHost + NavController for navigation between screens
5. Use remember/mutableStateOf for local state, ViewModel for complex state
6. Output EACH file in this format:
```kotlin
// File: FileName.kt
package <package>
import ...
<code>
```
7. ALWAYS include MainActivity.kt with setContent and the NavHost setup
8. Make the UI look polished with proper spacing, colors, and Material components
9. Do NOT use any external libraries beyond the standard Jetpack Compose + Material 3 + Navigation
10. Handle all screen sizes reasonably
''';

  String _buildPlanPrompt(String prompt, String appName, String packageName) => '''
I want to build an Android app. Plan the architecture for this app:

App Description: $prompt
App Name: $appName
Package: $packageName

Provide a brief plan with:
1. List of screens (max 5-6 for MVP)
2. Navigation flow between screens
3. Key data models needed
4. For each screen: what it shows and its main composables

Keep it concise - just the plan, no code yet.
''';

  String _buildCodePrompt(String prompt, String appName, String packageName, String plan) => '''
Generate the COMPLETE Android app code based on this plan.

App Description: $prompt
App Name: $appName
Package: $packageName

Architecture Plan:
$plan

Generate ALL Kotlin files needed for this app. Include:
1. MainActivity.kt - with setContent, theme, and NavHost setup
2. All Screen composables  
3. Any ViewModels needed
4. Data models
5. Navigation setup
6. A theme file if needed

Remember:
- Package name is: $packageName
- Use Jetpack Compose + Material 3
- Use NavHost for navigation
- Each file must be complete and compilable
- Format each file as:
```kotlin
// File: FileName.kt
<complete code>
```
''';
}
