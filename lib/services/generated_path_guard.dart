import 'dart:io';
import 'package:path/path.dart' as p;

String safeGeneratedKotlinPath(String raw, String packagePath) {
  final name = raw.trim().replaceAll('\\', '/');
  if (name.isEmpty || name.startsWith('/') || name.contains(':') ||
      name.split('/').any((part) => part.isEmpty || part == '.' || part == '..') ||
      !RegExp(r'^[A-Za-z0-9_./-]+$').hasMatch(name)) {
    throw FormatException('Unsafe generated Kotlin filename');
  }
  final relative = name.startsWith('app/src/main/java/')
      ? name : 'app/src/main/java/$packagePath/$name';
  final result = relative.endsWith('.kt') ? relative : '$relative.kt';
  if (!result.startsWith('app/src/main/java/') ||
      result.split('/').any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw FormatException('Source path must stay inside Java sources');
  }
  return result;
}

String safeGeneratedOutputPath(String outputDir, String relative) {
  final name = relative.replaceAll('\\', '/');
  if (name.isEmpty || name.startsWith('/') || name.contains(':') ||
      name.split('/').any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw FormatException('Unsafe generated output path');
  }
  final root = p.normalize(p.absolute(outputDir));
  final target = p.normalize(p.join(root, name));
  if (!p.isWithin(root, target)) throw FormatException('Path escapes output directory');
  return target;
}


/// Reject existing directory and file symlinks that escape the project root.
Future<String> safeGeneratedFileDestination(String outputDir, String relative) async {
  final root = Directory(outputDir);
  await root.create(recursive: true);
  final canonicalRoot = await root.resolveSymbolicLinks();
  final path = safeGeneratedOutputPath(canonicalRoot, relative);
  final parent = Directory(p.dirname(path));
  await parent.create(recursive: true);
  final realParent = await parent.resolveSymbolicLinks();
  if (!p.isWithin(canonicalRoot, realParent) &&
      !p.equals(canonicalRoot, realParent)) {
    throw FormatException('Generated output escapes project folder via symlink');
  }
  if (await FileSystemEntity.type(path, followLinks: false) == FileSystemEntityType.link) {
    throw FormatException('Generated output destination is a symlink');
  }
  return path;
}
