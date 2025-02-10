import 'package:file/memory.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';

import '../shared.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });
  group('RenderTag', () {
    late MemoryFileSystem fileSystem;
    late FileSystemRoot root;

    setUp(() {
      fileSystem = MemoryFileSystem();
      root = FileSystemRoot('/templates', fileSystem: fileSystem);
      evaluator.context.setRoot(root);

      // Set up some mock templates
      fileSystem.file('/templates/simple.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('Hello, {{ name }}!');
      fileSystem.file('/templates/with_vars.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('{{ greeting }}, {{ person }}!');
      fileSystem.file('/templates/for_loop.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('{% for item in items %}{{ item }} {% endfor %}');
      fileSystem.file('/templates/nested.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('{% render "simple.liquid" name: "World" %}');
      fileSystem.file('/templates/with_product.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('Product: {{ product.title }}');
    });

    test('renders a simple template', () {
      testParser('{% render "simple.liquid" name: "World" %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Hello, World!');
      });
    });

    test('renders a template with variables', () {
      testParser(
          '{% render "with_vars.liquid" greeting: "Hi", person: "John" %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Hi, John!');
      });
    });

    test('renders a template with a for loop', () {
      testParser('{% render "for_loop.liquid" items: (1..3) %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1 2 3 ');
      });
    });

    test('renders a nested template', () {
      testParser('{% render "nested.liquid" %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Hello, World!');
      });
    });

    test('throws exception for non-existent template', () {
      testParser('{% render "non_existent.liquid" %}', (document) {
        expect(() => evaluator.evaluate(document), throwsException);
      });
    });

    test('renders with "with" parameter', () {
      evaluator.context.setVariable('product', {'title': 'Awesome Shirt'});
      testParser('{% render "with_product.liquid" with product as product %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Product: Awesome Shirt');
      });
    });

    test('renders with "for" parameter', () {
      evaluator.context.setVariable('products', [
        {'title': 'Shirt'},
        {'title': 'Pants'},
        {'title': 'Hat'}
      ]);
      testParser('{% render "with_product.liquid" for products as product %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(),
            'Product: ShirtProduct: PantsProduct: Hat');
      });
    });

    test('respects variable scope', () {
      evaluator.context.setVariable('name', 'Outside');
      testParser('''
        Outside: {{ name }}
        {% render "simple.liquid" name: "Inside" %}
        Outside again: {{ name }}
      ''', (document) {
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
            'Outside: Outside Hello, Inside! Outside again: Outside');
      });
    });

    test('handles recursive rendering', () {
      fileSystem.file('/templates/recursive.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
        {% if depth > 0 %}
          Depth: {{ depth }}
          {% assign new_depth = depth | minus: 1 %}
          {% render "recursive.liquid" depth: new_depth %}
        {% else %}
          Bottom reached
        {% endif %}
        ''');

      testParser('{% render "recursive.liquid" depth: 3 %}', (document) {
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
            'Depth: 3 Depth: 2 Depth: 1 Bottom reached');
      });
    });

    test('handles errors in rendered template', () {
      fileSystem.file('/templates/error.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('{{ undefined_variable }}');

      testParser('{% render "error.liquid" %}', (document) {
        expect(evaluator.evaluate(document), '');
      });
    });
  });
}