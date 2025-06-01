import 'dart:io';
import 'package:test/test.dart';
import 'package:liquify/src/fs.dart';
import 'package:file/local.dart';

void main() {
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

    test(
        'FileSystemRoot works with default LocalFileSystem when fileSystem is null',
        () {
      // This should not throw and should use LocalFileSystem internally
      final rootWithNull = FileSystemRoot(tempDir.path, fileSystem: null);
      final source = rootWithNull.resolve('header.liquid');
      expect(source.content, equals('Header content'));
      expect(source.file?.path, contains('header.liquid'));
    });

    test('resolves template with extension fallback', () {
      // Only create a file with .liquid extension in tempDir
      final fallbackFile = File('${tempDir.path}/fallback.liquid');
      fallbackFile.writeAsStringSync('Fallback content');
      // Try resolving without extension, should find fallback.liquid
      final source = root.resolve('fallback');
      expect(source.content, equals('Fallback content'));
      expect(source.file?.path, contains('fallback.liquid'));
    });

    test('throws if no extension match is found', () {
      // Ensure no file with the name or extension exists in tempDir
      expect(() => root.resolve('doesnotexist'), throwsException);
    });

    test('resolves template with extension fallback asynchronously', () async {
      final fallbackFile = File('${tempDir.path}/fallback_async.liquid');
      fallbackFile.writeAsStringSync('Async fallback content');
      final source = await root.resolveAsync('fallback_async');
      expect(source.content, equals('Async fallback content'));
      expect(source.file?.path, contains('fallback_async.liquid'));
    });

    test('throws if no extension match is found asynchronously', () async {
      // Ensure no file with the name or extension exists in tempDir
      expect(() => root.resolveAsync('doesnotexist_async'), throwsException);
    });
  });
}
