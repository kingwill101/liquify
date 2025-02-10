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
  group('IfTag', () {
    test('basic if statement', () {
      testParser(
          '{% if true %}'
          'True'
          '{% endif %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'True');
      });
    });

    test('if-else statement', () {
      testParser(
          '{% if false %}'
          'True'
          '{% else %}'
          'False'
          '{% endif %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'False');
      });
    });

    test('nested if statements', () {
      testParser(
          '{% if true %}{% if false %}Inner False{% else %}Inner True{% endif %}{% endif %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Inner True');
      });
    });

    test('if statement with break', () {
      testParser(
          '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      });
    });

    test('if statement with continue', () {
      testParser(
          '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      });
    });
  });
}