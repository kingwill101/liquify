import 'package:liquify/parser.dart';

import '../support/shared.dart';
import '../support/golden_harness.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('TableRowTag', () {
    group('issues', () {
      setUp(() {
        evaluator.context.setVariable("keywords", [
          {"term": "Hi", "type": "One"},
          {"term": "Bye", "type": "One"},
          {"term": "Yes", "type": "Two"},
          {"term": "No"},
        ]);
      });
      test('issue-30', () {
        testParser(
          '''
<table>
{% tablerow keyword in keywords cols:4 %}

<span>{{keyword.term}}</span>
{%- if keyword.type == "One" %}
<sup>1</sup>
{% elsif keyword.type == "Two" %}
<sup>2</sup>
{% endif %}

{% endtablerow %}
</table>
        ''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(
              evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '<table>  <tr class="row1">    <td class="col1">      <span>Hi</span><sup>1</sup>    </td>    <td class="col2">      <span>Bye</span><sup>1</sup>    </td>    <td class="col3">      <span>Yes</span><sup>2</sup>    </td>    <td class="col4">      <span>No</span>    </td>  </tr></table>'
                  .replaceAll(RegExp(r'\s+'), ''),
            );
          },
        );
      });
    });

    setUp(() {
      evaluator.context.setVariable('collection', {
        'products': [
          {'title': 'Cool Shirt'},
          {'title': 'Alien Poster'},
          {'title': 'Batman Poster'},
          {'title': 'Bullseye Shirt'},
          {'title': 'Another Classic Vinyl'},
          {'title': 'Awesome Jeans'},
        ],
      });
    });

    group('sync evaluation', () {
      test('basic row iteration', () async {
        await testParser(
          '''<table>
{% tablerow product in collection.products %}
{{- product.title }}
{% endtablerow %}
</table>''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with cols attribute', () async {
        await testParser(
          '''<table>
{% tablerow product in collection.products cols:2 %}
{{- product.title }}
{% endtablerow %}
</table>''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with limit and cols attributes', () async {
        await testParser(
          '''<table>
{% tablerow item in (1..6) cols:2 limit:4 %}
  {{- item }}
{% endtablerow %}
</table>''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with offset and cols attributes', () async {
        await testParser(
          '''<table>
{% tablerow item in (1..6) cols:2 offset:3 %}
    {{- item }}
{% endtablerow %}
</table>''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with limit, offset and cols attributes', () async {
        await testParser(
          '''<table>
{% tablerow item in (1..10) cols:3 limit:6 offset:2 %}
  {{- item }}
{% endtablerow %}
</table>''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with range', () async {
        await testParser(
          '''<table>
{% assign num = 4 -%}
{% tablerow i in (1..num) %}
  {{- i }}
{% endtablerow %}
</table>''',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });
    });

    group('async evaluation', () {
      test('basic row iteration', () async {
        await testParser(
          '''<table>
{% tablerow product in collection.products %}
{{- product.title }}
{% endtablerow %}
</table>''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with cols attribute', () async {
        await testParser(
          '''<table>
{% tablerow product in collection.products cols:2 %}
{{- product.title }}
{% endtablerow %}
</table>''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with limit and cols attributes', () async {
        await testParser(
          '''<table>
{% tablerow item in (1..6) cols:2 limit:4 %}
  {{- item }}
{% endtablerow %}
</table>''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with offset and cols attributes', () async {
        await testParser(
          '''<table>
{% tablerow item in (1..6) cols:2 offset:3 %}
    {{- item }}
{% endtablerow %}
</table>''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with limit, offset and cols attributes', () async {
        await testParser(
          '''<table>
{% tablerow item in (1..10) cols:3 limit:6 offset:2 %}
  {{- item }}
{% endtablerow %}
</table>''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });

      test('with range', () async {
        await testParser(
          '''<table>
{% assign num = 4 -%}
{% tablerow i in (1..num) %}
  {{- i }}
{% endtablerow %}
</table>''',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), '''<table>
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
</table>''');
          },
        );
      });
    });
  });
}
