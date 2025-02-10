import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
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
}