import 'dart:io';
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
  test('rejects symlinked destinations even when their parents are safe', () async {
    final temp = await Directory.systemTemp.createTemp('generated-paths-');
    addTearDown(() async => temp.delete(recursive: true));
    final output = Directory(temp.path + '/output');
    await output.create();
    final outside = File(temp.path + '/private.txt');
    await outside.writeAsString('private');
    await Link(output.path + '/redirect.kt').create(outside.path);
    await expectLater(
      safeGeneratedFileDestination(output.path, 'redirect.kt'),
      throwsFormatException,
    );
    expect(await outside.readAsString(), 'private');
  });
  test('rejects existing directory symlinks escaping the project root', () async {
    final temp = await Directory.systemTemp.createTemp('generated-paths-');
    addTearDown(() async => temp.delete(recursive: true));
    final output = Directory(temp.path + '/output');
    final outside = Directory(temp.path + '/outside');
    await output.create();
    await outside.create();
    await Link(output.path + '/linked').create(outside.path);
    await expectLater(
      safeGeneratedFileDestination(output.path, 'linked/Leak.kt'),
      throwsFormatException,
    );
  });
}
