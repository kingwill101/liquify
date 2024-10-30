import 'package:file/memory.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('ForTag', () {
    test('basic iteration', () {
      testParser('{% for item in (1..3) %}{{ item }}{% endfor %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '123');
      });
    });

    test('else block', () {
      testParser(
        '{% for item in (1..0) %}{{ item }}{% else %}No items{% endfor %}',
        (document) {
          evaluator.evaluate(document);
          expect(evaluator.buffer.toString(), 'No items');
        },
      );
    });

    test('break tag', () {
      testParser(
          '{% for item in (1..5) %}'
          '{% if item == 3 %}'
          '{% break %}'
          '{% endif %}'
          '{{ item }}'
          '{% endfor %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      });
    });

    test('continue tag', () {
      testParser(
          '{% for item in (1..5) %}'
          '{% if item == 3 %}'
          '{% continue %}'
          '{% endif %}'
          '{{ item }}'
          '{% endfor %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      });
    });

    test('limit filter', () {
      testParser(
          '{% for item in (1..5) limit:3 %}'
          '{{ item }}'
          '{% endfor %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '123');
      });
    });

    test('offset filter', () {
      testParser(
          '{% for item in (1..5) offset:2 %}'
          '{{ item }}'
          '{% endfor %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '345');
      });
    });

    test('reversed filter', () {
      testParser('{% for item in (1..3) reversed %}{{ item }}{% endfor %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '321');
      });
    });

    test('forloop basic properties', () {
      testParser('''{% for item in (1..3) %}Index: {{ forloop.index }},
    Index0: {{ forloop.index0 }},
    First: {{ forloop.first }},
    Last: {{ forloop.last }},
    Length: {{ forloop.length }}
    {% endfor %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(
            evaluator.buffer
                .toString()
                .replaceAll(RegExp(r'\s+'), ' ')
                .replaceAll(RegExp(r'\n'), ' '),
            'Index: 1, Index0: 0, First: true, Last: false, Length: 3 Index: 2, Index0: 1, First: false, Last: false, Length: 3 Index: 3, Index0: 2, First: false, Last: true, Length: 3 ');
      });
    });

    test('forloop reverse index properties', () {
      testParser('''{% for item in (1..3) %}RIndex: {{ forloop.rindex }},
              RIndex0: {{ forloop.rindex0 }}
            {% endfor %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' '),
            'RIndex: 3, RIndex0: 2 RIndex: 2, RIndex0: 1 RIndex: 1, RIndex0: 0 ');
      });
    });

    test('nested loops and parentloop', () {
      testParser(
          '''{% for outer in (1..2) %}Outer: {{ outer }}{% for inner in (1..2) %}
    Inner: {{ inner }},
    Outer Index: {{ forloop.parentloop.index }},
    Inner Index: {{ forloop.index }}
    {% endfor %}
    {% endfor %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' '),
            'Outer: 1 Inner: 1, Outer Index: 1, Inner Index: 1 Inner: 2, Outer Index: 1, Inner Index: 2 Outer: 2 Inner: 1, Outer Index: 2, Inner Index: 1 Inner: 2, Outer Index: 2, Inner Index: 2 ');
      });
    });

    test('forloop with limit and offset', () {
      testParser('''
{% for item in (1..10) limit:3 offset:2 %}
{{ forloop.index }}: {{ item }}
{% endfor %}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n1: 3\n\n2: 4\n\n3: 5\n');
      });
    });

    test('forloop with reversed', () {
      testParser('''
    {% for item in (1..3) reversed %}
    {{ forloop.index }}: {{ item }}
    {% endfor %}
          ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' '),
            ' 1: 3 2: 2 3: 1 ');
      });
    });
  });

  group('IfTag', () {
    test('basic if statement', () {
      testParser(
          '{% if true %}'
          'True'
          '{% endif %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'True');
      });
    });

    test('if-else statement', () {
      testParser(
          '{% if false %}'
          'True'
          '{% else %}'
          'False'
          '{% endif %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'False');
      });
    });

    test('nested if statements', () {
      testParser(
          '{% if true %}{% if false %}Inner False{% else %}Inner True{% endif %}{% endif %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Inner True');
      });
    });

    test('if statement with break', () {
      testParser(
          '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      });
    });

    test('if statement with continue', () {
      testParser(
          '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      });
    });
  });

  group('CycleTag', () {
    test('basic cycle', () {
      testParser(
          '{% cycle "one", "two", "three" %}'
          '{% cycle "one", "two", "three" %}'
          '{% cycle "one", "two", "three" %}'
          '{% cycle "one", "two", "three" %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'onetwothreeone');
      });
    });

    test('cycle with groups', () {
      testParser(
          '{% cycle "first": "one", "two", "three" %}'
          '{% cycle "second": "one", "two", "three" %}'
          '{% cycle "second": "one", "two", "three" %}'
          '{% cycle "first": "one", "two", "three" %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'oneonetwotwo');
      });
    });
  });

  group('TableRowTag', () {
    setUp(() {
      evaluator.context.setVariable('collection', {
        'products': [
          {'title': 'Cool Shirt'},
          {'title': 'Alien Poster'},
          {'title': 'Batman Poster'},
          {'title': 'Bullseye Shirt'},
          {'title': 'Another Classic Vinyl'},
          {'title': 'Awesome Jeans'},
        ]
      });
    });

    test('basic row iteration', () {
      testParser('''<table>
{% tablerow product in collection.products %}
{{- product.title }}
{% endtablerow %}
</table>''', (document) {
        evaluator.evaluate(document);

        final expectedOutput = '''<table>
  <tr class="row1">
    <td class="col1">
      Cool Shirt
    </td>
    <td class="col2">
      Alien Poster
    </td>
    <td class="col3">
      Batman Poster
    </td>
    <td class="col4">
      Bullseye Shirt
    </td>
    <td class="col5">
      Another Classic Vinyl
    </td>
    <td class="col6">
      Awesome Jeans
    </td>
  </tr>
</table>''';

        expect(evaluator.buffer.toString(), expectedOutput);
      });
    });

    test('with cols attribute', () {
      testParser('''<table>
{% tablerow product in collection.products cols:2 %}
{{- product.title }}
{% endtablerow %}
</table>''', (document) {
        evaluator.evaluate(document);

        final expectedOutput = '''<table>
  <tr class="row1">
    <td class="col1">
      Cool Shirt
    </td>
    <td class="col2">
      Alien Poster
    </td>
  </tr>
  <tr class="row2">
    <td class="col1">
      Batman Poster
    </td>
    <td class="col2">
      Bullseye Shirt
    </td>
  </tr>
  <tr class="row3">
    <td class="col1">
      Another Classic Vinyl
    </td>
    <td class="col2">
      Awesome Jeans
    </td>
  </tr>
</table>''';

        expect(evaluator.buffer.toString(), expectedOutput);
      });
    });

    test('with limit and cols attributes', () {
      testParser('''<table>
{% tablerow item in (1..6) cols:2 limit:4 %}
  {{- item }}
{% endtablerow %}
</table>''', (document) {
        evaluator.evaluate(document);

        final expectedOutput = '''<table>
  <tr class="row1">
    <td class="col1">
      1
    </td>
    <td class="col2">
      2
    </td>
  </tr>
  <tr class="row2">
    <td class="col1">
      3
    </td>
    <td class="col2">
      4
    </td>
  </tr>
</table>''';

        expect(evaluator.buffer.toString(), expectedOutput);
      });
    });

    test('with offset and cols attributes', () {
      testParser('''<table>
{% tablerow item in (1..6) cols:2 offset:3 %}
    {{- item }}
{% endtablerow %}
</table>''', (document) {
        evaluator.evaluate(document);

        final expectedOutput = '''
<table>
  <tr class="row1">
    <td class="col1">
      4
    </td>
    <td class="col2">
      5
    </td>
  </tr>
  <tr class="row2">
    <td class="col1">
      6
    </td>
  </tr>
</table>''';

        expect(evaluator.buffer.toString(), expectedOutput);
      });
    });

    test('with limit, offset and cols attributes', () {
      testParser('''<table>
{% tablerow item in (1..10) cols:3 limit:6 offset:2 %}
  {{- item }}
{% endtablerow %}
</table>''', (document) {
        evaluator.evaluate(document);
        final expectedOutput = '''<table>
  <tr class="row1">
    <td class="col1">
      3
    </td>
    <td class="col2">
      4
    </td>
    <td class="col3">
      5
    </td>
  </tr>
  <tr class="row2">
    <td class="col1">
      6
    </td>
    <td class="col2">
      7
    </td>
    <td class="col3">
      8
    </td>
  </tr>
</table>''';
        expect(evaluator.buffer.toString(), expectedOutput);
      });
    });

    test('with range', () {
      testParser('''<table>
{% assign num = 4 -%}
{% tablerow i in (1..num) %}
  {{- i }}
{% endtablerow %}
</table>''', (document) {
        evaluator.evaluate(document);
        final expectedOutput = '''
<table>
  <tr class="row1">
    <td class="col1">
      1
    </td>
    <td class="col2">
      2
    </td>
    <td class="col3">
      3
    </td>
    <td class="col4">
      4
    </td>
  </tr>
</table>''';
        expect(evaluator.buffer.toString(), expectedOutput);
      });
    });
  });

  group('Unless Tag', () {
    test('renders when false', () {
      testParser(
          '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
          (document) {
        evaluator.context.setVariable('product', {'title': 'Terrible Shoes'});
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
      });
    });

    test('doesnt render when true', () {
      testParser(
          '{% unless product.title == "Awesome Shoes" %}These shoes are not awesome.{% endunless %}',
          (document) {
        evaluator.context
            .setVariable('product', {'title': 'These shoes are not awesome.'});
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
      });
    });
  });

  group('Capture Tag', () {
    test('outputs captured data', () {
      testParser(
          '{% capture my_variable %}I am being captured.{% endcapture %}{{ my_variable }}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'I am being captured.');
      });
    });
  });

  group('Increment Tag', () {
    test('increments variable', () {
      testParser(
          '{% increment my_counter %}{% increment my_counter %}{% increment my_counter %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '012');
      });
    });

    test('global variables are not affected by increment', () {
      testParser(
          '{% assign var = 10 %}{% increment var %}{% increment var %}{% increment var %}{{ var }}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '01210');
      });
    });
  });

  group('Decrement Tag', () {
    test('decrements variable', () {
      testParser('''
{% decrement my_counter %}
{% decrement my_counter %}
{% decrement my_counter %}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '-1\n-2\n-3');
      });
    });

    test('global variables are not affected by decrement', () {
      testParser('''{% assign var = 10 %}
{% decrement var %}
{% decrement var %}
{% decrement var %}
{{ var }}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n-1\n-2\n-3\n10');
      });
    });
  });

  group('Liquid Tag', () {
    test('assigns variable', () {
      testParser('''
{% liquid
 assign my_variable = "string"
%}
''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.context.getVariable('my_variable'), 'string');
      });
    });
  });

  group('Raw Tag', () {
    test('shows raw text', () {
      testParser('''{% raw %}{% liquid
 assign my_variable = "string"
%}
{% endraw %}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '''
{% liquid
 assign my_variable = "string"
%}
''');
      });
    });
  });

  group('Case/when tag', () {
    test('case tag with single match', () {
      testParser(
        '{% assign handle = "cake" %}'
        '{% case handle %}'
        '{% when "cake" %}'
        'This is a cake'
        '{% when "cookie" %}'
        'This is a cookie'
        '{% else %}'
        'This is not a cake nor a cookie'
        '{% endcase %}',
        (document) {
          evaluator.evaluate(document);
          expect(evaluator.buffer.toString().trim(), 'This is a cake');
        },
      );
    });
    test('case tag with multiple values in when', () {
      testParser(
          '{% assign handle = "biscuit" %}'
          '{% case handle %}'
          '{% when "cake" %}'
          'This is a cake'
          '{% when "cookie", "biscuit" %}'
          'This is a cookie or biscuit'
          '{% else %}'
          'This is something else'
          '{% endcase %}', (document) {
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().trim(), 'This is a cookie or biscuit');
      });
    });
  });

  test('case tag with else condition', () {
    testParser(
        '{% assign handle = "pie" %}'
        '{% case handle %}'
        '{% when "cake" %}'
        'This is a cake'
        '{% when "cookie" %}'
        'This is a cookie'
        '{% else %}'
        'This is neither a cake nor a cookie'
        '{% endcase %}', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString().trim(),
          'This is neither a cake nor a cookie');
    });
  });

  test('case tag with no matching condition and no else', () {
    testParser(
        '{% assign handle = "pie" %}'
        '{% case handle %}'
        '{% when "cake" %}'
        'This is a cake'
        '{% when "cookie" %}'
        'This is a cookie'
        '{% endcase %}', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), '');
    });
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

  group('truthy', () {
    test('variable', () {
      testParser('''
{% assign name = "Tobi" %}
{% if name %}
  truthy.
{% endif %}

      ''', (document) {
        evaluator.context.setVariable('variable', true);
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('truthy'));
      });
    });

    test('variable', () {
      testParser('''
{% if false %}
  falsy.
{% else %}
  not truthy 
{% endif %}

      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('not truthy'));
      });
    });

    test('empty string', () {
      testParser('''
        {% assign name = "" %}
        {% if name %}
          truthy.
        {% endif %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('truthy'));
      });
    });

    test('null', () {
      testParser('''
        {% assign name = null %}
        {% if name %}
          truthy.
        {% endif %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), isNot(contains('truthy')));
      });
    });

    test('binary operator and', () {
      testParser('''
        {% assign name = null %}
        {% if name and "" %}
          truthy.
        {% endif %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), isNot(contains('truthy')));
      });
    });

    test('binary operator or', () {
      testParser('''
        {% assign name = null %}
        {% if name or "" %}
          truthy.
        {% endif %}
      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('truthy'));
      });
    });
  });

  test('if/elif/elseif', () {
    testParser('''
        {% assign num = 1 %}
        {% if num == 2 %}
          num is 2
        {% elseif num == 1 %}
          num is 1
         {% else %}
            didn't find it
        {% endif %}
      ''', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), contains('num is 1'));
    });

    testParser('''
        {% assign num = 2 %}
        {% if num == 2 %}
          num is 2
        {% elseif num == 1 %}
          num is 1
         {% else %}
            didn't find it
        {% endif %}
      ''', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), contains('num is 2'));
    });

    testParser('''
        {% assign num = 4 %}
        {% if num == 2 %}
          num is 2
        {% elseif num == 1 %}
          num is 1
         {% else %}
            didn't find it
            {% if num > 2 %}
              it is greater than 2
            {% else %}
              it is not greater than 2
            {% endif %}
        {% endif %}
      ''', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), contains("didn't find it"));
      expect(evaluator.buffer.toString(), contains("it is greater than 2"));
    });

    testParser('''
        {% assign num = 4 %}
        {% if num == 2 %}
          num is 2
        {% elseif num == 1 %}
          num is 1
         {% else %}
            didn't find it
            {% if num > 5 %}
              it is greater than 2
            {% else %}
              it is not greater than 5
            {% endif %}
        {% endif %}
      ''', (document) {
      evaluator.evaluate(document);
      expect(evaluator.buffer.toString(), contains("didn't find it"));
      expect(evaluator.buffer.toString(), contains("it is not greater than 5"));
    });
  });
}
