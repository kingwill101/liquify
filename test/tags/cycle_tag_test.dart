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
  group('CycleTag', () {
    test('basic cycle', () {
      testParser(
          '{% cycle "one", "two", "three" %}'
          '{% cycle "one", "two", "three" %}'
          '{% cycle "one", "two", "three" %}'
          '{% cycle "one", "two", "three" %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'onetwothreeone');
      });
    });

    test('cycle with groups', () {
      testParser(
          '{% cycle "first": "one", "two", "three" %}'
          '{% cycle "second": "one", "two", "three" %}'
          '{% cycle "second": "one", "two", "three" %}'
          '{% cycle "first": "one", "two", "three" %}', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'oneonetwotwo');
      });
    });
  });
}