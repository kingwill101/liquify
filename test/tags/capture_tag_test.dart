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
  group('Capture Tag', () {
    test('outputs captured data', () {
      testParser(
          '{% capture my_variable %}I am being captured.{% endcapture %}{{ my_variable }}',
          (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'I am being captured.');
      });
    });
  });
}