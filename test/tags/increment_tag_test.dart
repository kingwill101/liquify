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

  group('IncrementTag', () {
    group('sync evaluation', () {
      test('starts from 0 and increments', () async {
        await testParser('''
          {% increment counter %}
          {% increment counter %}
          {% increment counter %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '012');
        });
      });

      test('is independent from assign', () async {
        await testParser('''
          {% assign counter = 42 %}
          {% increment counter %}
          {{ counter }}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '042');
        });
      });

      test('shares state with decrement', () async {
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
          {% increment counter1 %}
          {% increment counter2 %}
          {% increment counter1 %}
          {% increment counter2 %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '0011');
        });
      });
    });

    group('async evaluation', () {
      test('starts from 0 and increments', () async {
        await testParser('''
          {% increment counter %}
          {% increment counter %}
          {% increment counter %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '012');
        });
      });

      test('is independent from assign', () async {
        await testParser('''
          {% assign counter = 42 %}
          {% increment counter %}
          {{ counter }}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '042');
        });
      });

      test('shares state with decrement', () async {
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
          {% increment counter1 %}
          {% increment counter2 %}
          {% increment counter1 %}
          {% increment counter2 %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().replaceAll(RegExp(r'\s+'), ''),
              '0011');
        });
      });
    });
  });
}
