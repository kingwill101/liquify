import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:file/memory.dart';
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
  group('TableRowTag', () {
    late MemoryFileSystem fileSystem;
    late FileSystemRoot root;

    setUp(() {
      fileSystem = MemoryFileSystem();
      root = FileSystemRoot('/templates', fileSystem: fileSystem);
      evaluator.context.setRoot(root);

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
}