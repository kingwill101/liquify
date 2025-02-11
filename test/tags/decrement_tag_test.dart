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

  group('DecrementTag', () {
    group('sync evaluation', () {
      test('starts from -1', () async {
        await testParser('{% decrement counter %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '-1');
        });
      });

      test('decrements sequentially', () async {
        await testParser('''
          {% decrement counter %}
          {% decrement counter %}
          {% decrement counter %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '-1-2-3');
        });
      });

      test('is independent from assign', () async {
        await testParser('''
          {% assign counter = 42 %}
          {% decrement counter %}
          {{ counter }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '-142');
        });
      });

      test('shares state with increment', () async {
        await testParser('''
          {% increment counter %}
          {% decrement counter %}
          {% increment counter %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '0-10');
        });
      });

      test('maintains separate counters', () async {
        await testParser('''
          {% decrement counter1 %}
          {% decrement counter2 %}
          {% decrement counter1 %}
          {% decrement counter2 %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '-1-1-2-2');
        });
      });
    });

    group('async evaluation', () {
      test('starts from -1', () async {
        await testParser('{% decrement counter %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '-1');
        });
      });

      test('decrements sequentially', () async {
        await testParser('''
          {% decrement counter %}
          {% decrement counter %}
          {% decrement counter %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '-1-2-3');
        });
      });

      test('is independent from assign', () async {
        await testParser('''
          {% assign counter = 42 %}
          {% decrement counter %}
          {{ counter }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '-142');
        });
      });

      test('shares state with increment', () async {
        await testParser('''
          {% increment counter %}
          {% decrement counter %}
          {% increment counter %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '0-10');
        });
      });

      test('maintains separate counters', () async {
        await testParser('''
          {% decrement counter1 %}
          {% decrement counter2 %}
          {% decrement counter1 %}
          {% decrement counter2 %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '-1-1-2-2');
        });
      });
    });
  });
}
