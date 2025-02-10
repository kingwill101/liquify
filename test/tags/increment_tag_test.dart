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
  group('Increment Tag', () {
    test('increments variable', () {
      testParser(
          '{% increment my_counter %}{% increment my_counter %}{% increment my_counter %}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '012');
      });
    });

    test('global variables are not affected by increment', () {
      testParser(
          '{% assign var = 10 %}{% increment var %}{% increment var %}{% increment var %}{{ var }}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '01210');
      });
    });
  });
}