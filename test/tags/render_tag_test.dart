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

    // Templates for scope isolation testing
    fileSystem.file('/templates/assign_inside.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('{% assign secret = "leaked" %}{{ passed_var }}');
    fileSystem.file('/templates/try_global.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('Global: {{ global_var }}');
    fileSystem.file('/templates/modify_passed.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync(
          '{% assign passed_var = "modified" %}Modified: {{ passed_var }}');
    fileSystem.file('/templates/nested_assigns.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{% assign nested_var = "from_nested" %}
{% assign original_var = "overwritten_in_nested" %}
Nested: {{ nested_var }}
''');
    fileSystem.file('/templates/global_access.liquid')
      ..createSync(recursive: true)
      ..writeAsStringSync(
          '{% assign global_test = "should_not_leak" %}Accessing: {{ global_test }}');

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

      test('renders template with escaped quotes', () async {
        await testParser(
            r'{% render "simple.liquid" name: "John \"The Man\" Johnson" %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Hello, John "The Man" Johnson!');
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

    group('scope isolation tests - sync', () {
      test('variables assigned inside render do not leak to parent scope',
          () async {
        evaluator.context.setVariable('passed_var', 'original');

        await testParser('''
          Before: {{ passed_var }}
          {% render "assign_inside.liquid" passed_var: passed_var %}
          After: {{ passed_var }}
          Secret: {{ secret }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // The secret variable should not be accessible in parent scope
          expect(result, 'Before: original original After: original Secret:');
          expect(evaluator.context.getVariable('secret'), isNull);
        });
      });

      test(
          'global variables are not accessible in render without explicit passing',
          () async {
        evaluator.context.setVariable('global_var', 'global_value');

        await testParser('{% render "try_global.liquid" %}', (document) {
          evaluator.evaluateNodes(document.children);

          // Should render empty since global_var was not passed
          expect(evaluator.buffer.toString(), 'Global: ');
        });
      });

      test('global variables must be explicitly passed to be accessible',
          () async {
        evaluator.context.setVariable('global_var', 'global_value');

        await testParser(
            '{% render "try_global.liquid" global_var: global_var %}',
            (document) {
          evaluator.evaluateNodes(document.children);

          // Should render the value since it was explicitly passed
          expect(evaluator.buffer.toString(), 'Global: global_value');
        });
      });

      test('modifications to passed variables do not affect parent scope',
          () async {
        evaluator.context.setVariable('passed_var', 'original');

        await testParser('''
          Before: {{ passed_var }}
          {% render "modify_passed.liquid" passed_var: passed_var %}
          After: {{ passed_var }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // The passed variable should not be modified in the parent scope
          expect(result, 'Before: original Modified: modified After: original');
        });
      });

      test('passed variables override parent scope variables with same name',
          () async {
        // Set up a variable in parent scope
        evaluator.context.setVariable('name', 'parent_value');
        evaluator.context.setVariable('category', 'parent_category');

        // Create a template that uses these variable names
        fileSystem.file('/templates/variable_override.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
Name: {{ name }}
Category: {{ category }}
Parent var: {{ parent_only }}
''');

        await testParser('''
          Parent name: {{ name }}
          Parent category: {{ category }}
          {% render "variable_override.liquid" name: "passed_name", category: "passed_category" %}
          After render name: {{ name }}
          After render category: {{ category }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // The render should use passed values, not parent values
          expect(result, contains('Parent name: parent_value'));
          expect(result, contains('Parent category: parent_category'));
          expect(result,
              contains('Name: passed_name')); // Inside render uses passed value
          expect(
              result,
              contains(
                  'Category: passed_category')); // Inside render uses passed value
          expect(result, contains('Parent var:')); // Empty because not passed
          expect(result,
              contains('After render name: parent_value')); // Parent unchanged
          expect(
              result,
              contains(
                  'After render category: parent_category')); // Parent unchanged

          // Verify parent scope variables are unchanged
          expect(evaluator.context.getVariable('name'), 'parent_value');
          expect(evaluator.context.getVariable('category'), 'parent_category');
        });
      });

      test('nested render calls maintain isolation', () async {
        evaluator.context.setVariable('original_var', 'parent_value');

        fileSystem.file('/templates/nested_render.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
Middle: {{ original_var }}
{% render "nested_assigns.liquid" %}
After nested: {{ nested_var }}{{ original_var }}
''');

        await testParser('''
          Parent: {{ original_var }}
          {% render "nested_render.liquid" original_var: original_var %}
          Parent after: {{ original_var }}{{ nested_var }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // Variables from nested render should not leak to any parent level
          expect(result, contains('Parent: parent_value'));
          expect(result, contains('Middle: parent_value'));
          expect(result, contains('Nested: from_nested'));
          expect(result, contains('Parent after: parent_value'));
          expect(evaluator.context.getVariable('nested_var'), isNull);
        });
      });

      test('forloop variables in render do not leak', () async {
        evaluator.context.setVariable('items', ['a', 'b', 'c']);

        fileSystem.file('/templates/forloop_template.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{% for item in items %}
  Item: {{ item }}
  Index: {{ forloop.index }}
{% endfor %}
Outside loop: {{ forloop.index }}{{ item }}
''');

        await testParser('''
          {% render "forloop_template.liquid" items: items %}
          Parent forloop: {{ forloop.index }}{{ item }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer.toString();

          // forloop and item variables should not be accessible in parent
          expect(result, contains('Item: a'));
          expect(result, contains('Index: 1'));
          expect(result, contains('Outside loop:')); // Should be empty
          expect(result, contains('Parent forloop:')); // Should be empty
        });
      });

      test('complex nested scope isolation', () async {
        evaluator.context.setVariable('level', 'root');
        evaluator.context.setVariable('shared', 'root_shared');

        fileSystem.file('/templates/level1.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
L1 level: {{ level }}
L1 shared: {{ shared }}
{% assign level = "level1" %}
{% assign l1_only = "level1_var" %}
{% render "level2.liquid" shared: shared %}
L1 after: {{ level }}{{ l1_only }}
''');

        fileSystem.file('/templates/level2.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
L2 level: {{ level }}
L2 shared: {{ shared }}
L2 l1_only: {{ l1_only }}
{% assign level = "level2" %}
{% assign l2_only = "level2_var" %}
''');

        await testParser('''
          Root: {{ level }}{{ shared }}
          {% render "level1.liquid" level: level %}
          Root after: {{ level }}{{ shared }}{{ l1_only }}{{ l2_only }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // Verify complete isolation between all levels
          expect(result, contains('Root: rootroot_shared'));
          expect(result, contains('L1 level: root'));
          expect(result, contains('L2 level:')); // Empty - not passed
          expect(result, contains('L2 l1_only:')); // Empty - from parent render
          expect(result, contains('L1 after: level1level1_var'));
          expect(result, contains('Root after: rootroot_shared')); // No leakage

          // Ensure no variables leaked to root
          expect(evaluator.context.getVariable('l1_only'), isNull);
          expect(evaluator.context.getVariable('l2_only'), isNull);
          expect(evaluator.context.getVariable('level'), 'root');
        });
      });

      test('render with for maintains isolation per iteration', () async {
        evaluator.context.setVariable('items', [
          {'name': 'item1', 'value': 1},
          {'name': 'item2', 'value': 2}
        ]);

        fileSystem.file('/templates/item_processor.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
Processing: {{ item.name }}
{% assign processed = item.value | times: 2 %}
Result: {{ processed }}
''');

        await testParser('''
          {% render "item_processor.liquid" for items as item %}
          Parent processed: {{ processed }}
          Parent item: {{ item.name }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          expect(result, contains('Processing: item1'));
          expect(result, contains('Result: 2'));
          expect(result, contains('Processing: item2'));
          expect(result, contains('Result: 4'));
          expect(result, contains('Parent processed:')); // Empty
          expect(result, contains('Parent item:')); // Empty

          // Variables from render for should not leak
          expect(evaluator.context.getVariable('processed'), isNull);
          expect(evaluator.context.getVariable('item'), isNull);
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

    group('scope isolation tests - async', () {
      test('variables assigned inside render do not leak to parent scope',
          () async {
        evaluator.context.setVariable('passed_var', 'original');

        await testParser('''
          Before: {{ passed_var }}
          {% render "assign_inside.liquid" passed_var: passed_var %}
          After: {{ passed_var }}
          Secret: {{ secret }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // The secret variable should not be accessible in parent scope
          expect(result, 'Before: original original After: original Secret:');
          expect(evaluator.context.getVariable('secret'), isNull);
        });
      });

      test(
          'global variables are not accessible in render without explicit passing',
          () async {
        evaluator.context.setVariable('global_var', 'global_value');

        await testParser('{% render "try_global.liquid" %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);

          // Should render empty since global_var was not passed
          expect(evaluator.buffer.toString(), 'Global: ');
        });
      });

      test('global variables must be explicitly passed to be accessible',
          () async {
        evaluator.context.setVariable('global_var', 'global_value');

        await testParser(
            '{% render "try_global.liquid" global_var: global_var %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);

          // Should render the value since it was explicitly passed
          expect(evaluator.buffer.toString(), 'Global: global_value');
        });
      });

      test('modifications to passed variables do not affect parent scope',
          () async {
        evaluator.context.setVariable('passed_var', 'original');

        await testParser('''
          Before: {{ passed_var }}
          {% render "modify_passed.liquid" passed_var: passed_var %}
          After: {{ passed_var }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // The passed variable should not be modified in the parent scope
          expect(result, 'Before: original Modified: modified After: original');
        });
      });

      test('passed variables override parent scope variables with same name',
          () async {
        // Set up a variable in parent scope
        evaluator.context.setVariable('name', 'parent_value');
        evaluator.context.setVariable('category', 'parent_category');

        // Create a template that uses these variable names
        fileSystem.file('/templates/variable_override.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
Name: {{ name }}
Category: {{ category }}
Parent var: {{ parent_only }}
''');

        await testParser('''
          Parent name: {{ name }}
          Parent category: {{ category }}
          {% render "variable_override.liquid" name: "passed_name", category: "passed_category" %}
          After render name: {{ name }}
          After render category: {{ category }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // The render should use passed values, not parent values
          expect(result, contains('Parent name: parent_value'));
          expect(result, contains('Parent category: parent_category'));
          expect(result,
              contains('Name: passed_name')); // Inside render uses passed value
          expect(
              result,
              contains(
                  'Category: passed_category')); // Inside render uses passed value
          expect(result, contains('Parent var:')); // Empty because not passed
          expect(result,
              contains('After render name: parent_value')); // Parent unchanged
          expect(
              result,
              contains(
                  'After render category: parent_category')); // Parent unchanged

          // Verify parent scope variables are unchanged
          expect(evaluator.context.getVariable('name'), 'parent_value');
          expect(evaluator.context.getVariable('category'), 'parent_category');
        });
      });

      test('complex nested scope isolation', () async {
        evaluator.context.setVariable('level', 'root');
        evaluator.context.setVariable('shared', 'root_shared');

        fileSystem.file('/templates/level1.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
L1 level: {{ level }}
L1 shared: {{ shared }}
{% assign level = "level1" %}
{% assign l1_only = "level1_var" %}
{% render "level2.liquid" shared: shared %}
L1 after: {{ level }}{{ l1_only }}
''');

        fileSystem.file('/templates/level2.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
L2 level: {{ level }}
L2 shared: {{ shared }}
L2 l1_only: {{ l1_only }}
{% assign level = "level2" %}
{% assign l2_only = "level2_var" %}
''');

        await testParser('''
          Root: {{ level }}{{ shared }}
          {% render "level1.liquid" level: level %}
          Root after: {{ level }}{{ shared }}{{ l1_only }}{{ l2_only }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // Verify complete isolation between all levels
          expect(result, contains('Root: rootroot_shared'));
          expect(result, contains('L1 level: root'));
          expect(result, contains('L2 level:')); // Empty - not passed
          expect(result, contains('L2 l1_only:')); // Empty - from parent render
          expect(result, contains('L1 after: level1level1_var'));
          expect(result, contains('Root after: rootroot_shared')); // No leakage

          // Ensure no variables leaked to root
          expect(evaluator.context.getVariable('l1_only'), isNull);
          expect(evaluator.context.getVariable('l2_only'), isNull);
          expect(evaluator.context.getVariable('level'), 'root');
        });
      });

      test('render with for maintains isolation per iteration', () async {
        evaluator.context.setVariable('items', [
          {'name': 'item1', 'value': 1},
          {'name': 'item2', 'value': 2}
        ]);

        fileSystem.file('/templates/item_processor.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
Processing: {{ item.name }}
{% assign processed = item.value | times: 2 %}
Result: {{ processed }}
''');

        await testParser('''
          {% render "item_processor.liquid" for items as item %}
          Parent processed: {{ processed }}
          Parent item: {{ item.name }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          expect(result, contains('Processing: item1'));
          expect(result, contains('Result: 2'));
          expect(result, contains('Processing: item2'));
          expect(result, contains('Result: 4'));
          expect(result, contains('Parent processed:')); // Empty
          expect(result, contains('Parent item:')); // Empty

          // Variables from render for should not leak
          expect(evaluator.context.getVariable('processed'), isNull);
          expect(evaluator.context.getVariable('item'), isNull);
        });
      });

      test('render by default does not have access to parent scope', () async {
        evaluator.context.setVariable('items', [
          {'name': 'item1', 'value': 1},
          {'name': 'item2', 'value': 2}
        ]);

        fileSystem.file('/templates/item_processor.liquid')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{% if not items %}
No parent scoped items
{% else %}
Has parent scoped items
{% endif %}
''');

        await testParser('''
{% render "item_processor.liquid"%}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          final result = evaluator.buffer
              .toString()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          expect(result, contains('No parent scoped items'));
        });
      });
    });
  });
}
