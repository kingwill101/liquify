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

  group('AssignTag', () {
    group('sync evaluation', () {
      test('assigns simple value', () async {
        await testParser('''
              {% assign my_variable = "hello" %}
              {{ my_variable }}
            ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), equals('hello'));
        });
      });

      test('assigns value with filter', () async {
        await testParser('''
              {% assign my_variable = "hello" | upcase %}
              {{ my_variable }}
            ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), equals('HELLO'));
        });
      });

      test('assigns result of expression', () async {
        await testParser('''
              {% assign x = 2 %}
              {% assign result = x | plus: 3 %}
              {{ result }}
            ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), equals('5'));
        });
      });

      test('assigns with multiple filters', () async {
        await testParser('''
              {% assign my_variable = "hello world" | capitalize | split: " " | first %}
              {{ my_variable }}
            ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), equals('Hello'));
        });
      });
    });

    group('async evaluation', () {
      test('assigns simple value', () async {
        await testParser('''
              {% assign my_variable = "hello" %}
              {{ my_variable }}
            ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), equals('hello'));
        });
      });

      test('assigns value with filter', () async {
        await testParser('''
              {% assign my_variable = "hello" | upcase %}
              {{ my_variable }}
            ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), equals('HELLO'));
        });
      });

      test('assigns result of expression', () async {
        await testParser('''
              {% assign x = 2 %}
              {% assign result = x | plus: 3 %}
              {{ result }}
            ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), equals('5'));
        });
      });

      test('assigns with multiple filters', () async {
        await testParser('''
              {% assign my_variable = "hello world" | capitalize | split: " " | first %}
              {{ my_variable }}
            ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), equals('Hello'));
        });
      });
    });
  });
}
