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
    test('variable', () {
      testParser('''
  {% assign name = "Tobi" %}
  {% if name %}
  truthy.
  {% endif %}

      ''', (document) {
        evaluator.context.setVariable('variable', true);
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('truthy'));
      });
    });

    test('variable', () {
      testParser('''
    {% if false %}
    falsy.
    {% else %}
    not truthy
    {% endif %}

      ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('not truthy'));
      });
    });

    test('empty string', () {
      testParser('''
    {% assign name = "" %}
    {% if name %}
    truthy.
    {% endif %}
    ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('truthy'));
      });
    });

    test('null', () {
      testParser('''
    {% assign name = null %}
    {% if name %}
    truthy.
    {% endif %}
    ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), isNot(contains('truthy')));
      });
    });

    test('binary operator and', () {
      testParser('''
    {% assign name = null %}
    {% if name and "" %}
    truthy.
    {% endif %}
    ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), isNot(contains('truthy')));
      });
    });

    test('binary operator or', () {
      testParser('''
    {% assign name = null %}
    {% if name or "" %}
    truthy.
    {% endif %}
    ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), contains('truthy'));
      });
    });
  });
}
