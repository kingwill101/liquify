import 'dart:io';
import 'package:test/test.dart';
import 'package:liquify/src/fs.dart';
import 'package:file/local.dart';

void main(){
  group('FileSystemRoot', () {
  late Directory tempDir;
  late FileSystemRoot root;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('liquify_test_');
    // Create a template file
    final templateFile = File('${tempDir.path}/header.liquid');
    templateFile.writeAsStringSync('Header content');
    root = FileSystemRoot(tempDir.path, fileSystem: LocalFileSystem());
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('resolves existing template file', () {
    final source = root.resolve('header.liquid');
    expect(source.content, equals('Header content'));
    expect(source.file?.path, contains('header.liquid'));
  });

  test('throws exception for missing template file', () {
    expect(() => root.resolve('missing.liquid'), throwsException);
  });

  test('resolves existing template file asynchronously', () async {
    final source = await root.resolveAsync('header.liquid');
    expect(source.content, equals('Header content'));
    expect(source.file?.path, contains('header.liquid'));
  });

  test('throws exception for missing template file asynchronously', () async {
    expect(() => root.resolveAsync('missing.liquid'), throwsException);
  });

  test('FileSystemRoot works with default LocalFileSystem when fileSystem is null', () {
    // This should not throw and should use LocalFileSystem internally
    final rootWithNull = FileSystemRoot(tempDir.path, fileSystem: null);
    final source = rootWithNull.resolve('header.liquid');
    expect(source.content, equals('Header content'));
    expect(source.file?.path, contains('header.liquid'));
  });
});

}