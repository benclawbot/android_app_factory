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
