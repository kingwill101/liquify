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
  group('Raw Tag', () {
    test('shows raw text', () {
      testParser('''{% raw %}{% liquid
  assign my_variable = "string"
  %}
  {% endraw %}''', (document) {
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '''
  {% liquid
  assign my_variable = "string"
  %}
  ''');
      });
    });
  });
}

