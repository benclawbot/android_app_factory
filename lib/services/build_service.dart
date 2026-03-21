import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// A single Kotlin compiler error extracted from Gradle output.
class BuildError {
  /// Absolute file path on disk, e.g.
  /// `C:/Android Apps Built/myapp/app/src/main/java/com/example/myapp/GameScreen.kt`
  final String absolutePath;

  /// Path relative to the project root, e.g.
  /// `app/src/main/java/com/example/myapp/GameScreen.kt`
  final String relativePath;

  /// Just the filename, e.g. `GameScreen.kt`
  final String fileName;

  final int line;
  final int column;
  final String message;

  const BuildError({
    required this.absolutePath,
    required this.relativePath,
    required this.fileName,
    required this.line,
    required this.column,
    required this.message,
  });

  @override
  String toString() => '$fileName:$line:$column $message';
}

/// Result of a single Gradle build run.
class BuildResult {
  final bool success;

  /// All stdout+stderr lines collected during the build.
  final List<String> outputLines;

  /// Structured Kotlin compiler errors (empty on success).
  final List<BuildError> errors;

  /// Absolute path to the debug APK on success, null otherwise.
  final String? apkPath;

  const BuildResult({
    required this.success,
    required this.outputLines,
    required this.errors,
    this.apkPath,
  });
}

/// Runs `gradlew assembleDebug` inside [projectPath] and streams output
/// through [onLine]. Returns a structured [BuildResult].
class BuildService {
  final void Function(String line) onLine;

  BuildService({required this.onLine});

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<BuildResult> runBuild(String projectPath) async {
    final javaHome = _findJavaHome();
    final gradlewExe = p.join(projectPath, 'gradlew.bat');

    if (!File(gradlewExe).existsSync()) {
      final msg = '❌ gradlew.bat not found at $projectPath';
      onLine(msg);
      return BuildResult(
        success: false,
        outputLines: [msg],
        errors: [],
      );
    }

    if (javaHome == null) {
      final msg = '❌ No suitable JDK found (need JDK 17 or 21). '
          'Install one or set JAVA_HOME.';
      onLine(msg);
      return BuildResult(success: false, outputLines: [msg], errors: []);
    }

    onLine('☕ Using JDK: $javaHome');
    onLine('🔨 Running: gradlew.bat assembleDebug');

    final env = Map<String, String>.from(Platform.environment)
      ..['JAVA_HOME'] = javaHome;

    final outputLines = <String>[];

    try {
      // Use cmd.exe so gradlew.bat executes properly
      final process = await Process.start(
        'cmd.exe',
        ['/c', 'gradlew.bat', 'assembleDebug', '--no-daemon', '--stacktrace'],
        workingDirectory: projectPath,
        environment: env,
        runInShell: false,
      );

      // Stream stdout
      process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen((line) {
        outputLines.add(line);
        onLine(line);
      });

      // Stream stderr
      process.stderr
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen((line) {
        outputLines.add(line);
        onLine(line);
      });

      final exitCode = await process.exitCode;

      // Check for fatal errors that exit code 0 doesn't catch
      // (e.g. missing gradle-wrapper.jar, ClassNotFoundException)
      final outputText = outputLines.join('\n');
      final hasFatalError =
          outputText.contains('ClassNotFoundException') ||
          outputText.contains('Could not find or load main class') ||
          outputText.contains('gradle-wrapper.jar not found') ||
          outputText.contains('Error: Could not find or load');

      if (exitCode == 0 && !hasFatalError) {
        final apk = _findApk(projectPath);
        if (apk != null) {
          onLine('');
          onLine('✅ Build succeeded! Exit code: 0');
          onLine('📦 APK: $apk');
          return BuildResult(
            success: true,
            outputLines: outputLines,
            errors: [],
            apkPath: apk,
          );
        } else {
          // Exit code 0 but no APK found — treat as failure
          onLine('');
          onLine('❌ Build returned exit code 0 but no APK was produced.');
          return BuildResult(
            success: false,
            outputLines: outputLines,
            errors: [],
          );
        }
      } else {
        final errors = _parseErrors(outputLines, projectPath);
        onLine('');
        if (hasFatalError) {
          onLine('❌ Build failed — fatal error detected in output.');
        } else {
          onLine('❌ Build failed (exit code $exitCode). '
              '${errors.length} error(s) found.');
        }
        return BuildResult(
          success: false,
          outputLines: outputLines,
          errors: errors,
        );
      }
    } on ProcessException catch (e) {
      final msg = '❌ Failed to start Gradle: $e';
      onLine(msg);
      return BuildResult(
        success: false,
        outputLines: [msg],
        errors: [],
      );
    }
  }

  // ── Java discovery ────────────────────────────────────────────────────────

  /// Returns the JAVA_HOME for a JDK 17 or 21. Tries in order:
  /// 1. Existing JAVA_HOME if it works (version 17–24 acceptable for Gradle 8.14)
  /// 2. Eclipse Adoptium jdk-21 / jdk-17
  /// 3. Android Studio embedded JDK
  /// 4. LOCALAPPDATA JetBrains / IntelliJ bundled JDK
  String? _findJavaHome() {
    // Helper: check if a path contains a java executable
    bool hasJava(String dir) =>
        File(p.join(dir, 'bin', 'java.exe')).existsSync() ||
        File(p.join(dir, 'bin', 'java')).existsSync();

    // 1. Try existing JAVA_HOME — skip Java 25+ (unsupported by Gradle 8.14)
    final existing = Platform.environment['JAVA_HOME'];
    if (existing != null && existing.isNotEmpty && hasJava(existing)) {
      final version = _getJavaVersion(existing);
      if (version != null && version >= 17 && version <= 24) {
        return existing;
      }
    }

    // 2. Eclipse Adoptium common paths
    final adoptium = [
      r'C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot',
      r'C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot',
      r'C:\Program Files\Eclipse Adoptium\jdk-17',
      r'C:\Program Files\Eclipse Adoptium\jdk-21',
    ];
    for (final path in adoptium) {
      if (hasJava(path)) return path;
    }

    // 3. Search Eclipse Adoptium directory for any JDK 17–21
    for (final adoptiumRoot in [
      r'C:\Program Files\Eclipse Adoptium',
      r'C:\Program Files\Microsoft',
    ]) {
      final dir = Directory(adoptiumRoot);
      if (dir.existsSync()) {
        for (final entry in dir.listSync().whereType<Directory>()) {
          final name = p.basename(entry.path).toLowerCase();
          if ((name.contains('jdk-17') || name.contains('jdk-21')) &&
              hasJava(entry.path)) {
            return entry.path;
          }
        }
      }
    }

    // 4. Android Studio embedded JDK (ships with JBR 17 or 21)
    final studioJdk = [
      r'C:\Program Files\Android\Android Studio\jbr',
      r'C:\Program Files\Android\Android Studio\jre',
    ];
    for (final path in studioJdk) {
      if (hasJava(path)) return path;
    }

    // 5. SDKMAN, asdf, scoop, chocolatey common paths
    final home = Platform.environment['USERPROFILE'] ?? r'C:\Users\thoma';
    final misc = [
      '$home\\.sdkman\\candidates\\java\\current',
      r'C:\ProgramData\scoop\apps\openjdk17\current',
      r'C:\tools\openjdk17',
    ];
    for (final path in misc) {
      if (hasJava(path)) return path;
    }

    return null;
  }

  int? _getJavaVersion(String javaHome) {
    try {
      final result = Process.runSync(
        p.join(javaHome, 'bin', 'java.exe'),
        ['-version'],
        stderrEncoding: const SystemEncoding(),
      );
      final output = result.stderr.toString();
      // e.g. 'openjdk version "21.0.1" 2023-10-17' or 'java version "17.0.9"'
      final match = RegExp(r'"(\d+)[\.\d]*"').firstMatch(output);
      if (match != null) return int.tryParse(match.group(1)!);
    } catch (_) {}
    return null;
  }

  // ── APK discovery ─────────────────────────────────────────────────────────

  String? _findApk(String projectPath) {
    final candidates = [
      p.join(projectPath, 'app', 'build', 'outputs', 'apk', 'debug',
          'app-debug.apk'),
      p.join(projectPath, 'app', 'build', 'outputs', 'apk', 'app-debug.apk'),
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    // Recursive search as fallback
    try {
      final outputDir =
          Directory(p.join(projectPath, 'app', 'build', 'outputs'));
      if (outputDir.existsSync()) {
        final apks = outputDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.apk'))
            .toList();
        if (apks.isNotEmpty) return apks.first.path;
      }
    } catch (_) {}
    return null;
  }

  // ── Error parsing ─────────────────────────────────────────────────────────

  /// Parses lines like:
  ///   e: file:///C:/path/to/File.kt: (74, 5): Unresolved reference 'foo'
  /// or (Kotlin 2.x format):
  ///   e: file:///C:/path/to/File.kt:74:5 Unresolved reference 'foo'
  List<BuildError> _parseErrors(
      List<String> lines, String projectPath) {
    final errors = <BuildError>[];
    // Pattern 1: e: file:///...: (line, col): message
    final re1 = RegExp(
      r"^e: file:///(.+?):\s*\((\d+),\s*(\d+)\):\s*(.+)$",
    );
    // Pattern 2: e: file:///...:line:col message
    final re2 = RegExp(
      r"^e: file:///(.+?):(\d+):(\d+)\s+(.+)$",
    );

    final seen = <String>{};

    for (final line in lines) {
      final trimmed = line.trim();
      RegExpMatch? m = re1.firstMatch(trimmed) ?? re2.firstMatch(trimmed);
      if (m == null) continue;

      final rawPath = m.group(1)!.replaceAll('%20', ' ');
      final lineNum = int.tryParse(m.group(2)!) ?? 0;
      final col = int.tryParse(m.group(3)!) ?? 0;
      final msg = m.group(4)!.trim();

      // Deduplicate same file+line+message
      final key = '$rawPath:$lineNum:$msg';
      if (seen.contains(key)) continue;
      seen.add(key);

      // Make relative path
      final normalised =
          rawPath.replaceAll('\\', '/').replaceAll(projectPath.replaceAll('\\', '/'), '').trimLeft();
      final rel = normalised.startsWith('/') ? normalised.substring(1) : normalised;

      errors.add(BuildError(
        absolutePath: rawPath,
        relativePath: rel,
        fileName: p.basename(rawPath),
        line: lineNum,
        column: col,
        message: msg,
      ));
    }

    return errors;
  }
}
