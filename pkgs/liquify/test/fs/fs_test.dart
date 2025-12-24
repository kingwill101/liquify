import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';

class MockRoot extends Root {
  final Map<String, String> templates;
  final Duration? delay;

  MockRoot(this.templates, {this.delay});

  @override
  Source resolve(String relPath) {
    final content = templates[relPath];
    if (content == null) {
      throw Exception('Template not found: $relPath');
    }
    return Source(Uri.parse(relPath), content, this);
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    final content = templates[relPath];
    if (content == null) {
      throw Exception('Template not found: $relPath');
    }
    return Source(Uri.parse(relPath), content, this);
  }
}

void main() {
  group('MockRoot', () {
    late MockRoot root;
    late Environment context;
    late Evaluator evaluator;

    setUp(() {
      root = MockRoot({
        'simple.liquid': 'Hello, {{ name }}!',
        'with_vars.liquid': '{{ greeting }}, {{ person }}!',
        'for_loop.liquid': '{% for item in items %}{{ item }} {% endfor %}',
        'nested.liquid': '{% render "simple.liquid" name: "World" %}',
      });
      context = Environment()..setRoot(root);
      evaluator = Evaluator(context);
    });

    group('sync operations', () {
      test('resolves existing template', () {
        final source = root.resolve('simple.liquid');
        expect(source.content, equals('Hello, {{ name }}!'));
        expect(source.file?.path, equals('simple.liquid'));
      });

      test('throws exception for non-existent template', () {
        expect(() => root.resolve('non_existent.liquid'), throwsException);
      });

      test('evaluator can resolve and parse template', () {
        final nodes = evaluator.resolveAndParseTemplate('simple.liquid');
        expect(nodes, isNotEmpty);
      });

      test('evaluator can resolve and parse template with variables', () {
        final nodes = evaluator.resolveAndParseTemplate('with_vars.liquid');
        expect(nodes, isNotEmpty);
      });

      test('evaluator can resolve and parse template with for loop', () {
        final nodes = evaluator.resolveAndParseTemplate('for_loop.liquid');
        expect(nodes, isNotEmpty);
      });

      test('evaluator can resolve and parse nested template', () {
        final nodes = evaluator.resolveAndParseTemplate('nested.liquid');
        expect(nodes, isNotEmpty);
      });
    });

    group('async operations', () {
      test('resolves existing template asynchronously', () async {
        final source = await root.resolveAsync('simple.liquid');
        expect(source.content, equals('Hello, {{ name }}!'));
        expect(source.file?.path, equals('simple.liquid'));
      });

      test('throws exception for non-existent template asynchronously',
          () async {
        expect(() => root.resolveAsync('non_existent.liquid'), throwsException);
      });

      test('handles delayed template resolution', () async {
        final delayedRoot = MockRoot({'delayed.liquid': 'Delayed content'},
            delay: Duration(milliseconds: 100));

        final stopwatch = Stopwatch()..start();
        await delayedRoot.resolveAsync('delayed.liquid');
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
      });
    });

    group('error handling', () {
      test('handles sync resolution errors gracefully', () {
        expect(() => root.resolve('missing.liquid'), throwsException);
      });

      test('handles async resolution errors gracefully', () async {
        expect(() => root.resolveAsync('missing.liquid'), throwsException);
      });
    });
  });
}
