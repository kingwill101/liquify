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
    group('sync evaluation', () {
      test('basic iteration', () async {
        await testParser('{% for item in (1..3) %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '123');
        });
      });

      test('else block', () async {
        await testParser(
          '{% for item in (1..0) %}{{ item }}{% else %}No items{% endfor %}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'No items');
          },
        );
      });

      test('break tag', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '12');
        });
      });

      test('continue tag', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '1245');
        });
      });

      test('limit filter', () async {
        await testParser(
            '{% for item in (1..5) limit:3 %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '123');
        });
      });

      test('offset filter', () async {
        await testParser(
            '{% for item in (1..5) offset:2 %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '345');
        });
      });

      test('reversed filter', () async {
        await testParser(
            '{% for item in (1..3) reversed %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '321');
        });
      });

      test('forloop basic properties', () async {
        await testParser('''
          {% for item in (1..3) %}
            Index:{{ forloop.index }},
            Index0:{{ forloop.index0 }},
            First:{{ forloop.first }},
            Last:{{ forloop.last }},
            Length:{{ forloop.length }}
          {% endfor %}''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Index:1, Index0:0, First:true, Last:false, Length:3 Index:2, Index0:1, First:false, Last:false, Length:3 Index:3, Index0:2, First:false, Last:true, Length:3');
        });
      });

      test('nested loops and parentloop', () async {
        await testParser('''
          {% for outer in (1..2) %}
            {% for inner in (1..2) %}
              Outer:{{ forloop.parentloop.index }},
              Inner:{{ forloop.index }}
            {% endfor %}
          {% endfor %}''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Outer:1, Inner:1 Outer:1, Inner:2 Outer:2, Inner:1 Outer:2, Inner:2');
        });
      });

      test('iterates over map key/value pairs', () async {
        evaluator.context.setVariable('metadata', {
          'description': 'A website description',
          'author': 'John Doe',
          'keywords': 'test, liquid, template'
        });

        await testParser(
            '{% for pair in metadata %}{{ pair[0] }}:{{ pair[1] }}{% unless forloop.last %},{% endunless %}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          final result = evaluator.buffer.toString();

          expect(result, contains('description:A website description'));
          expect(result, contains('author:John Doe'));
          expect(result, contains('keywords:test, liquid, template'));

          expect(result.split(',').length, equals(5));
        });
      });
    });

    group('async evaluation', () {
      test('basic iteration', () async {
        await testParser('{% for item in (1..3) %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '123');
        });
      });

      test('else block', () async {
        await testParser(
          '{% for item in (1..0) %}{{ item }}{% else %}No items{% endfor %}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'No items');
          },
        );
      });

      test('break tag', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '12');
        });
      });

      test('continue tag', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '1245');
        });
      });

      test('limit filter', () async {
        await testParser(
            '{% for item in (1..5) limit:3 %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '123');
        });
      });

      test('offset filter', () async {
        await testParser(
            '{% for item in (1..5) offset:2 %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '345');
        });
      });

      test('reversed filter', () async {
        await testParser(
            '{% for item in (1..3) reversed %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '321');
        });
      });

      test('forloop basic properties', () async {
        await testParser('''
          {% for item in (1..3) %}
            Index:{{ forloop.index }},
            Index0:{{ forloop.index0 }},
            First:{{ forloop.first }},
            Last:{{ forloop.last }},
            Length:{{ forloop.length }}
          {% endfor %}''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Index:1, Index0:0, First:true, Last:false, Length:3 Index:2, Index0:1, First:false, Last:false, Length:3 Index:3, Index0:2, First:false, Last:true, Length:3');
        });
      });

      test('nested loops and parentloop', () async {
        await testParser('''
          {% for outer in (1..2) %}
            {% for inner in (1..2) %}
              Outer:{{ forloop.parentloop.index }},
              Inner:{{ forloop.index }}
            {% endfor %}
          {% endfor %}''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer
                  .toString()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              'Outer:1, Inner:1 Outer:1, Inner:2 Outer:2, Inner:1 Outer:2, Inner:2');
        });
      });
    });
  });
}
