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

  group('truthy', () {
    group('sync evaluation', () {
      test('variable is truthy', () async {
        await testParser('''
          {% assign name = "Tobi" %}
          {% if name %}
          truthy.
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), contains('truthy'));
        });
      });

      test('false is falsy', () async {
        await testParser('''
          {% if false %}
          falsy.
          {% else %}
          not truthy
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), contains('not truthy'));
        });
      });

      test('empty string is truthy', () async {
        await testParser('''
          {% assign name = "" %}
          {% if name %}
          truthy.
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), contains('truthy'));
        });
      });

      test('null is falsy', () async {
        await testParser('''
          {% assign name = null %}
          {% if name %}
          truthy.
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), isNot(contains('truthy')));
        });
      });

      test('binary operator and evaluates correctly', () async {
        await testParser('''
          {% assign name = null %}
          {% if name and "" %}
          truthy.
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), isNot(contains('truthy')));
        });
      });

      test('binary operator or evaluates correctly', () async {
        await testParser('''
          {% assign name = null %}
          {% if name or "" %}
          truthy.
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), contains('truthy'));
        });
      });
    });

    group('async evaluation', () {
      test('variable is truthy', () async {
        await testParser('''
          {% assign name = "Tobi" %}
          {% if name %}
          truthy.
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), contains('truthy'));
        });
      });

      test('false is falsy', () async {
        await testParser('''
          {% if false %}
          falsy.
          {% else %}
          not truthy
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), contains('not truthy'));
        });
      });

      test('empty string is truthy', () async {
        await testParser('''
          {% assign name = "" %}
          {% if name %}
          truthy.
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), contains('truthy'));
        });
      });

      test('null is falsy', () async {
        await testParser('''
          {% assign name = null %}
          {% if name %}
          truthy.
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), isNot(contains('truthy')));
        });
      });

      test('binary operator and evaluates correctly', () async {
        await testParser('''
          {% assign name = null %}
          {% if name and "" %}
          truthy.
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), isNot(contains('truthy')));
        });
      });

      test('binary operator or evaluates correctly', () async {
        await testParser('''
          {% assign name = null %}
          {% if name or "" %}
          truthy.
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), contains('truthy'));
        });
      });
    });
  });
}
