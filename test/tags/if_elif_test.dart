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

  group('if/elif/elseif tag', () {
    group('sync evaluation', () {
      test('handles elseif with first condition false', () async {
        await testParser('''
          {% assign num = 1 %}
          {% if num == 2 %}
            num is 2
          {% elseif num == 1 %}
            num is 1
          {% else %}
            didn't find it
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), equals('num is 1'));
        });
      });

      test('handles first condition true', () async {
        await testParser('''
          {% assign num = 2 %}
          {% if num == 2 %}
            num is 2
          {% elseif num == 1 %}
            num is 1
          {% else %}
            didn't find it
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), equals('num is 2'));
        });
      });

      test('handles nested if in else block - condition true', () async {
        await testParser('''
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
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), contains("didn't find it"));
          expect(evaluator.buffer.toString(), contains("it is greater than 2"));
        });
      });

      test('handles nested if in else block - condition false', () async {
        await testParser('''
          {% assign num = 4 %}
          {% if num == 2 %}
            num is 2
          {% elseif num == 1 %}
            num is 1
          {% else %}
            didn't find it
            {% if num > 5 %}
              it is greater than 5
            {% else %}
              it is not greater than 5
            {% endif %}
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), contains("didn't find it"));
          expect(evaluator.buffer.toString(),
              contains("it is not greater than 5"));
        });
      });
    });

    group('async evaluation', () {
      test('handles elseif with first condition false', () async {
        await testParser('''
          {% assign num = 1 %}
          {% if num == 2 %}
            num is 2
          {% elseif num == 1 %}
            num is 1
          {% else %}
            didn't find it
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), equals('num is 1'));
        });
      });

      test('handles first condition true', () async {
        await testParser('''
          {% assign num = 2 %}
          {% if num == 2 %}
            num is 2
          {% elseif num == 1 %}
            num is 1
          {% else %}
            didn't find it
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), equals('num is 2'));
        });
      });

      test('handles nested if in else block - condition true', () async {
        await testParser('''
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
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), contains("didn't find it"));
          expect(evaluator.buffer.toString(), contains("it is greater than 2"));
        });
      });

      test('handles nested if in else block - condition false', () async {
        await testParser('''
          {% assign num = 4 %}
          {% if num == 2 %}
            num is 2
          {% elseif num == 1 %}
            num is 1
          {% else %}
            didn't find it
            {% if num > 5 %}
              it is greater than 5
            {% else %}
              it is not greater than 5
            {% endif %}
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), contains("didn't find it"));
          expect(evaluator.buffer.toString(),
              contains("it is not greater than 5"));
        });
      });
    });
  });
}
