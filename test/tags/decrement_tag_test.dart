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
  group('Decrement Tag', () {
    test('decrements variable', () {
      testParser('''
  {% decrement my_counter %}
  {% decrement my_counter %}
  {% decrement my_counter %}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '-1\n-2\n-3');
      });
    });

    test('global variables are not affected by decrement', () {
      testParser('''{% assign var = 10 %}
    {% decrement var %}
    {% decrement var %}
    {% decrement var %}
    {{ var }}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '\n-1\n-2\n-3\n10');
      });
    });
  });
}