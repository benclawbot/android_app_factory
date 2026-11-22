import 'package:flutter_test/flutter_test.dart';
import 'package:android_app_factory/services/generated_path_guard.dart';

void main() {
  test('accepts legitimate Kotlin source filenames', () {
    expect(safeGeneratedKotlinPath('ui/MainActivity.kt', 'com/example/demo'),
      'app/src/main/java/com/example/demo/ui/MainActivity.kt');
    expect(safeGeneratedKotlinPath('app/src/main/java/com/example/demo/A.kt', 'com/example/demo'),
      'app/src/main/java/com/example/demo/A.kt');
  });
  test('rejects absolute paths and traversal on Windows and POSIX', () {
    for (final filename in [
      '../evil.kt', 'a/../../evil.kt', r'a\..\evil.kt', '/tmp/evil.kt',
      r'C:\tmp\evil.kt', r'\\server\share\evil.kt', 'a//b.kt',
      './Foo.kt', 'name:bad.kt',
    ]) {
      expect(() => safeGeneratedKotlinPath(filename, 'com/example/demo'),
        throwsFormatException, reason: filename);
    }
  });
  test('bounds every generated output path', () {
    expect(() => safeGeneratedOutputPath('/tmp/output', '../secret'), throwsFormatException);
    expect(() => safeGeneratedOutputPath('/tmp/output', r'C:\Windows\secret'), throwsFormatException);
    expect(safeGeneratedOutputPath('/tmp/output', 'app/Foo.kt'), contains('Foo.kt'));
  });
}
