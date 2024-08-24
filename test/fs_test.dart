import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';

class MockRoot implements Root {
  final Map<String, String> templates;

  MockRoot(this.templates);

  @override
  Source resolve(String relPath) {
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
}
