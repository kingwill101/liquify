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
  group('Assign Tag', () {
    test('assigns variable', () {
      testParser('''
  {% liquid
  assign my_variable = "string"
  %}
  ''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.context.getVariable('my_variable'), 'string');
      });
    });
  });
}
