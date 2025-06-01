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
      final rootThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: true);
      expect(() => rootThrow.resolve('missing.liquid'),
          throwsA(isA<TemplateNotFoundException>()));
    });

    test('resolves existing template file asynchronously', () async {
      final source = await root.resolveAsync('header.liquid');
      expect(source.content, equals('Header content'));
      expect(source.file?.path, contains('header.liquid'));
    });

    test('throws exception for missing template file asynchronously', () async {
      final rootThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: true);
      expect(() => rootThrow.resolveAsync('missing.liquid'),
          throwsA(isA<TemplateNotFoundException>()));
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
      final rootThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: true);
      expect(() => rootThrow.resolve('doesnotexist'),
          throwsA(isA<TemplateNotFoundException>()));
    });

    test('resolves template with extension fallback asynchronously', () async {
      final fallbackFile = File('${tempDir.path}/fallback_async.liquid');
      fallbackFile.writeAsStringSync('Async fallback content');
      final source = await root.resolveAsync('fallback_async');
      expect(source.content, equals('Async fallback content'));
      expect(source.file?.path, contains('fallback_async.liquid'));
    });

    test('throws if no extension match is found asynchronously', () async {
      final rootThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: true);
      expect(() => rootThrow.resolveAsync('doesnotexist_async'),
          throwsA(isA<TemplateNotFoundException>()));
    });

    test('returns empty Source if throwOnMissing is false (sync)', () {
      final rootNoThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: false);
      final source = rootNoThrow.resolve('doesnotexist');
      expect(source.content, equals(''));
      expect(source.file, isNull);
    });

    test('returns empty Source if throwOnMissing is false (async)', () async {
      final rootNoThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: false);
      final source = await rootNoThrow.resolveAsync('doesnotexist_async');
      expect(source.content, equals(''));
      expect(source.file, isNull);
    });

    test('throws TemplateNotFoundException if throwOnMissing is true (sync)',
        () {
      final rootThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: true);
      expect(() => rootThrow.resolve('doesnotexist'),
          throwsA(isA<TemplateNotFoundException>()));
    });

    test('throws TemplateNotFoundException if throwOnMissing is true (async)',
        () async {
      final rootThrow = FileSystemRoot(tempDir.path,
          fileSystem: LocalFileSystem(), throwOnMissing: true);
      expect(() => rootThrow.resolveAsync('doesnotexist_async'),
          throwsA(isA<TemplateNotFoundException>()));
    });
  });

  group('MapRoot', () {
    test('returns content for existing template', () {
      final root = MapRoot({'foo': 'bar'});
      final source = root.resolve('foo');
      expect(source.content, equals('bar'));
      expect(source.file, isNull);
    });

    test('returns empty Source for missing template by default', () {
      final root = MapRoot({'foo': 'bar'});
      final source = root.resolve('missing');
      expect(source.content, equals(''));
      expect(source.file, isNull);
    });

    test('throws TemplateNotFoundException if throwOnMissing is true (sync)',
        () {
      final root = MapRoot({'foo': 'bar'}, throwOnMissing: true);
      expect(() => root.resolve('missing'),
          throwsA(isA<TemplateNotFoundException>()));
    });

    test('returns empty Source for missing template (async)', () async {
      final root = MapRoot({'foo': 'bar'});
      final source = await root.resolveAsync('missing');
      expect(source.content, equals(''));
      expect(source.file, isNull);
    });

    test('throws TemplateNotFoundException if throwOnMissing is true (async)',
        () async {
      final root = MapRoot({'foo': 'bar'}, throwOnMissing: true);
      expect(() => root.resolveAsync('missing'),
          throwsA(isA<TemplateNotFoundException>()));
    });
  });
}
