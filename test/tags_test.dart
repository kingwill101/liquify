import 'package:file/memory.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/registry.dart';
import 'package:petitparser/core.dart';
import 'package:test/test.dart';

void main() {
  late Evaluator evaluator;
  late Parser parser;

  setUp(() {
    registerBuiltIns();

    evaluator = Evaluator(Environment());
    parser = LiquidGrammar().build();
  });

  group('ForTag', () {
    test('basic iteration', () {
      final result =
          parser.parse('{% for item in (1..3) %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '123');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('else block', () {
      final result = parser.parse('{% for item in (1..0) %}'
          '{{ item }}'
          '{% else %}'
          'No items'
          '{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'No items');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('break tag', () {
      final result = parser.parse('{% for item in (1..5) %}'
          '{% if item == 3 %}'
          '{% break %}'
          '{% endif %}'
          '{{ item }}'
          '{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('continue tag', () {
      final result = parser.parse('{% for item in (1..5) %}'
          '{% if item == 3 %}'
          '{% continue %}'
          '{% endif %}'
          '{{ item }}'
          '{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('limit filter', () {
      final result = parser.parse(''
          '{% for item in (1..5) limit:3 %}'
          '{{ item }}'
          '{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '123');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('offset filter', () {
      final result = parser.parse(''
          '{% for item in (1..5) offset:2 %}'
          '{{ item }}'
          '{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '345');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('reversed filter', () {
      final result = parser
          .parse('{% for item in (1..3) reversed %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '321');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('forloop basic properties', () {
      final result =
          parser.parse('''{% for item in (1..3) %}Index: {{ forloop.index }},
Index0: {{ forloop.index0 }},
First: {{ forloop.first }},
Last: {{ forloop.last }},
Length: {{ forloop.length }}
{% endfor %}
      ''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(
            evaluator.buffer
                .toString()
                .replaceAll(RegExp(r'\s+'), ' ')
                .replaceAll(RegExp(r'\n'), ' '),
            'Index: 1, Index0: 0, First: true, Last: false, Length: 3 Index: 2, Index0: 1, First: false, Last: false, Length: 3 Index: 3, Index0: 2, First: false, Last: true, Length: 3 ');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('forloop reverse index properties', () {
      final result =
          parser.parse('''{% for item in (1..3) %}RIndex: {{ forloop.rindex }},
          RIndex0: {{ forloop.rindex0 }}
        {% endfor %}
      ''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' '),
            'RIndex: 3, RIndex0: 2 RIndex: 2, RIndex0: 1 RIndex: 1, RIndex0: 0 ');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('nested loops and parentloop', () {
      final result = parser.parse(
          '''{% for outer in (1..2) %}Outer: {{ outer }}{% for inner in (1..2) %}
Inner: {{ inner }},
Outer Index: {{ forloop.parentloop.index }},
Inner Index: {{ forloop.index }}
{% endfor %}
{% endfor %}
      ''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' '),
            'Outer: 1 Inner: 1, Outer Index: 1, Inner Index: 1 Inner: 2, Outer Index: 1, Inner Index: 2 Outer: 2 Inner: 1, Outer Index: 2, Inner Index: 1 Inner: 2, Outer Index: 2, Inner Index: 2 ');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('forloop with limit and offset', () {
      final result = parser.parse('''
{% for item in (1..10) limit:3 offset:2 %}
{{ forloop.index }}: {{ item }}
{% endfor %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n1: 3\n\n2: 4\n\n3: 5\n');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('forloop with reversed', () {
      final result = parser.parse('''
{% for item in (1..3) reversed %}
{{ forloop.index }}: {{ item }}
{% endfor %}
      ''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' '),
            ' 1: 3 2: 2 3: 1 ');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('IfTag', () {
    test('basic if statement', () {
      final result = parser.parse('{% if true %}'
          'True'
          '{% endif %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'True');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('if-else statement', () {
      final result = parser.parse(''
          '{% if false %}'
          'True'
          '{% else %}'
          'False'
          '{% endif %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'False');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('nested if statements', () {
      final result = parser.parse(
          '{% if true %}{% if false %}Inner False{% else %}Inner True{% endif %}{% endif %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Inner True');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('if statement with break', () {
      final result = parser.parse(
          '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('if statement with continue', () {
      final result = parser.parse(
          '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('CycleTag', () {
    test('basic cycle', () {
      final source = '''
{% cycle "one", "two", "three" %}
{% cycle "one", "two", "three" %}
{% cycle "one", "two", "three" %}
{% cycle "one", "two", "three" %}''';

      final result = parser.parse(source);
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'one\ntwo\nthree\none');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('cycle with groups', () {
      final result = parser.parse('''
{% cycle "first": "one", "two", "three" %}
{% cycle "second": "one", "two", "three" %}
{% cycle "second": "one", "two", "three" %}
{% cycle "first": "one", "two", "three" %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'one\none\ntwo\ntwo');
      } else {
        fail('Parsing failed: ${result.message}');
      }
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
      final result = parser.parse('''<table>
{% tablerow product in collection.products %}
{{ product.title }}
{% endtablerow %}
</table>''');
      if (result is Success) {
        final document = result.value;

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
      } else {
        fail('Parsing failed: ${result.message} ${result.toPositionString()} ');
      }
    });

    test('with cols attribute', () {
      final result = parser.parse('''<table>
{% tablerow product in collection.products cols:2 %}
  {{ product.title }}
{% endtablerow %}
</table>
''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);

        final expectedOutput = '''
<table>
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
</table>
''';

        expect(evaluator.buffer.toString(), expectedOutput);
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('with limit and cols attributes', () {
      final result = parser.parse('''<table>
{% tablerow item in (1..6) cols:2 limit:4 %}
  {{ item }}
{% endtablerow %}
</table>
''');
      if (result is Success) {
        final document = result.value;
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
  </tr>
  <tr class="row2">
    <td class="col1">
      3
    </td>
    <td class="col2">
      4
    </td>
  </tr>
</table>
''';

        expect(evaluator.buffer.toString(), expectedOutput);
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('with offset and cols attributes', () {
      final result = parser.parse('''<table>
{% tablerow item in (1..6) cols:2 offset:3 %}
   {{ item }}
{% endtablerow %}
</table>
''');
      if (result is Success) {
        final document = result.value;
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
</table>
''';

        expect(evaluator.buffer.toString(), expectedOutput);
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('with limit, offset and cols attributes', () {
      final result = parser.parse('''<table>
{% tablerow item in (1..10) cols:3 limit:6 offset:2 %}
  {{ item }}
{% endtablerow %}
</table>
''');
      if (result is Success) {
        final document = result.value;
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
</table>
''';

        expect(evaluator.buffer.toString(), expectedOutput);
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('with range', () {
      final result = parser.parse('''<table>
{% assign num = 4 %}
{% tablerow i in (1..num) %}
  {{ i }}
{% endtablerow %}
</table>
''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);

        final expectedOutput = '''<table>
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
</table>
''';
        expect(evaluator.buffer.toString(), expectedOutput);
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('Unless Tag', () {
    test('renders when false', () {
      evaluator.context.setVariable('product', {'title': 'Terrible Shoes'});
      final result =
          parser.parse('''{% unless product.title == "Awesome Shoes" %}
These shoes are not awesome.{% endunless %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('doesnt render when true', () {
      evaluator.context
          .setVariable('product', {'title': 'These shoes are not awesome.'});
      final result =
          parser.parse('''{% unless product.title == "Awesome Shoes" %}
These shoes are not awesome.{% endunless %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'These shoes are not awesome.');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('Capture Tag', () {
    test('outputs captured data', () {
      final result = parser.parse(
          '''{% capture my_variable %}I am being captured.{% endcapture %}
{{ my_variable }}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'I am being captured.\n');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('Increment Tag', () {
    test('increments variable', () {
      final result = parser.parse('''{% increment my_counter %}
{% increment my_counter %}
{% increment my_counter %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '0\n1\n2');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('global variables are not affected by increment', () {
      final result = parser.parse('''{% assign var = 10 %}
{% increment var %}
{% increment var %}
{% increment var %}
{{ var }}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n0\n1\n2\n10');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('Decrement Tag', () {
    test('increments variable', () {
      final result = parser.parse('''
{% decrement my_counter %}
{% decrement my_counter %}
{% decrement my_counter %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '-1\n-2\n-3');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('global variables are not affected by increment', () {
      final result = parser.parse('''{% assign var = 10 %}
{% decrement var %}
{% decrement var %}
{% decrement var %}
{{ var }}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n-1\n-2\n-3\n10');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('Liquid Tag', () {
    test('increments variable', () {
      final result = parser.parse('''
{% liquid
 assign my_variable = "string"
%}
''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.context.getVariable('my_variable'), 'string');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });
  group('Raw Tag', () {
    test('shows raw text', () {
      final result = parser.parse('''{% raw %}{% liquid
 assign my_variable = "string"
%}
{% endraw %}''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '''
{% liquid
 assign my_variable = "string"
%}
''');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('Case/when tag', () {
    test('case tag with single match', () {
      final result = parser.parse('''
        {% assign handle = "cake" %}
        {% case handle %}
          {% when "cake" %}
            This is a cake
          {% when "cookie" %}
            This is a cookie
          {% else %}
            This is not a cake nor a cookie
        {% endcase %}
      ''');

      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().trim(), 'This is a cake');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('case tag with multiple values in when', () {
      final result = parser.parse('''
        {% assign handle = "biscuit" %}
        {% case handle %}
          {% when "cake" %}
            This is a cake
          {% when "cookie", "biscuit" %}
            This is a cookie or biscuit
          {% else %}
            This is something else
        {% endcase %}
      ''');

      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().trim(), 'This is a cookie or biscuit');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('case tag with else condition', () {
      final result = parser.parse('''
        {% assign handle = "pie" %}
        {% case handle %}
          {% when "cake" %}
            This is a cake
          {% when "cookie" %}
            This is a cookie
          {% else %}
            This is neither a cake nor a cookie
        {% endcase %}
      ''');

      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString().trim(),
            'This is neither a cake nor a cookie');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('case tag with no matching condition and no else', () {
      final result = parser.parse('''{% assign handle = "pie" %}
{% case handle %}
  {% when "cake" %}
    This is a cake
  {% when "cookie" %}
    This is a cookie
{% endcase %}''');

      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n');
      } else {
        fail('Parsing failed: ${result.message}');
      }
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
      final result = parser.parse('{% render "simple.liquid" name: "World" %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Hello, World!');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('renders a template with variables', () {
      final result = parser.parse(
          '{% render "with_vars.liquid" greeting: "Hi", person: "John" %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Hi, John!');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('renders a template with a for loop', () {
      final result =
          parser.parse('{% render "for_loop.liquid" items: (1..3) %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1 2 3 ');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('renders a nested template', () {
      final result = parser.parse('{% render "nested.liquid" %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Hello, World!');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('throws exception for non-existent template', () {
      final result = parser.parse('{% render "non_existent.liquid" %}');
      if (result is Success) {
        final document = result.value;
        expect(() => evaluator.evaluate(document), throwsException);
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('renders with "with" parameter', () {
      evaluator.context.setVariable('product', {'title': 'Awesome Shirt'});
      final result = parser
          .parse('{% render "with_product.liquid" with product as product %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Product: Awesome Shirt');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('renders with "for" parameter', () {
      evaluator.context.setVariable('products', [
        {'title': 'Shirt'},
        {'title': 'Pants'},
        {'title': 'Hat'}
      ]);
      final result = parser
          .parse('{% render "with_product.liquid" for products as product %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(),
            'Product: ShirtProduct: PantsProduct: Hat');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('respects variable scope', () {
      evaluator.context.setVariable('name', 'Outside');
      final result = parser.parse('''
        Outside: {{ name }}
        {% render "simple.liquid" name: "Inside" %}
        Outside again: {{ name }}
      ''');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
            'Outside: Outside Hello, Inside! Outside again: Outside');
      } else {
        fail('Parsing failed: ${result.message}');
      }
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

      final result = parser.parse('{% render "recursive.liquid" depth: 3 %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(
            evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
            'Depth: 3 Depth: 2 Depth: 1 Bottom reached');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('handles errors in rendered template', () {
      fileSystem.file('/templates/error.liquid')
        ..createSync(recursive: true)
        ..writeAsStringSync('{{ undefined_variable }}');

      final result = parser.parse('{% render "error.liquid" %}');
      if (result is Success) {
        final document = result.value;
        expect(evaluator.evaluate(document), '');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });
}
