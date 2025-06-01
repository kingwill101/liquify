import 'package:file/memory.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';

import '../shared.dart';

void main() {
  late Evaluator evaluator;
  late MemoryFileSystem fileSystem;
  late FileSystemRoot root;

  setUp(() {
    evaluator = Evaluator(Environment());
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

    // Add navigation component template
    fileSystem.file('/templates/components/navigation.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''{% comment %}Navigation Component
Usage:
{% render 'components/navigation' %}
{% render 'components/navigation', current_page: 'posts' %}
Parameters:
- current_page: Optional current page for highlighting active nav items
{% endcomment %}
''');
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('RenderTag', () {
    group('sync evaluation', () {
      test('renders a simple template', () async {
        await testParser('{% render "simple.liquid" name: "World" %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Hello, World!');
        });
      });

      test('renders a template with variables', () async {
        await testParser(
            '{% render "with_vars.liquid" greeting: "Hi", person: "John" %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Hi, John!');
        });
      });

      test('renders a template with a for loop', () async {
        await testParser('{% render "for_loop.liquid" items: (1..3) %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '1 2 3 ');
        });
      });

      test('renders a nested template', () async {
        await testParser('{% render "nested.liquid" %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Hello, World!');
        });
      });

      test('throws exception for non-existent template', () async {
        // Create a root that throws on missing templates
        final throwingRoot = FileSystemRoot('/templates',
            fileSystem: fileSystem, throwOnMissing: true);
        evaluator.context.setRoot(throwingRoot);

        await testParser('{% render "non_existent.liquid" %}', (document) {
          expect(() => evaluator.evaluateNodes(document.children),
              throwsException);
        });
      });

      test('renders with "with" parameter', () async {
        evaluator.context.setVariable('product', {'title': 'Awesome Shirt'});
        await testParser(
            '{% render "with_product.liquid" with product as product %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Product: Awesome Shirt');
        });
      });

      test('renders with "for" parameter', () async {
        evaluator.context.setVariable('products', [
          {'title': 'Shirt'},
          {'title': 'Pants'},
          {'title': 'Hat'}
        ]);
        await testParser(
            '{% render "with_product.liquid" for products as product %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(),
              'Product: ShirtProduct: PantsProduct: Hat');
        });
      });

      test('respects variable scope', () async {
        evaluator.context.setVariable('name', 'Outside');
        await testParser('''
          Outside: {{ name }}
          {% render "simple.liquid" name: "Inside" %}
          Outside again: {{ name }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Outside: Outside Hello, Inside! Outside again: Outside');
        });
      });

      test('handles recursive rendering', () async {
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

        await testParser('{% render "recursive.liquid" depth: 3 %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Depth: 3 Depth: 2 Depth: 1 Bottom reached');
        });
      });

      test('render tag does not render render tags in comment tags', () async {
        await testParser(
            '{% render "components/navigation.liquid" current_page: "posts" %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer.toString().trim();

          // Verify basic navigation structure
          expect(result, isEmpty);
        });
      });
    });

    group('async evaluation', () {
      test('renders a simple template', () async {
        await testParser('{% render "simple.liquid" name: "World" %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'Hello, World!');
        });
      });

      test('renders a template with variables', () async {
        await testParser(
            '{% render "with_vars.liquid" greeting: "Hi", person: "John" %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'Hi, John!');
        });
      });

      test('renders a template with a for loop', () async {
        await testParser('{% render "for_loop.liquid" items: (1..3) %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '1 2 3 ');
        });
      });

      test('renders a nested template', () async {
        await testParser('{% render "nested.liquid" %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'Hello, World!');
        });
      });

      test('throws exception for non-existent template', () async {
        // Create a root that throws on missing templates
        final throwingRoot = FileSystemRoot('/templates',
            fileSystem: fileSystem, throwOnMissing: true);
        evaluator.context.setRoot(throwingRoot);

        await testParser('{% render "non_existent.liquid" %}',
            (document) async {
          expect(() => evaluator.evaluateNodesAsync(document.children),
              throwsException);
        });
      });

      test('renders with "with" parameter', () async {
        evaluator.context.setVariable('product', {'title': 'Awesome Shirt'});
        await testParser(
            '{% render "with_product.liquid" with product as product %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'Product: Awesome Shirt');
        });
      });

      test('renders with "for" parameter', () async {
        evaluator.context.setVariable('products', [
          {'title': 'Shirt'},
          {'title': 'Pants'},
          {'title': 'Hat'}
        ]);
        await testParser(
            '{% render "with_product.liquid" for products as product %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(),
              'Product: ShirtProduct: PantsProduct: Hat');
        });
      });

      test('respects variable scope', () async {
        evaluator.context.setVariable('name', 'Outside');
        await testParser('''
          Outside: {{ name }}
          {% render "simple.liquid" name: "Inside" %}
          Outside again: {{ name }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Outside: Outside Hello, Inside! Outside again: Outside');
        });
      });

      test('handles recursive rendering', () async {
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

        await testParser('{% render "recursive.liquid" depth: 3 %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Depth: 3 Depth: 2 Depth: 1 Bottom reached');
        });
      });

      test('render tag does not render render tags in comment tags', () async {
        await testParser(
            '{% render "components/navigation.liquid" current_page: "posts" %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer.toString().trim();

          // Verify basic navigation structure
          expect(result, isEmpty);
        });
      });
    });
  });
}
