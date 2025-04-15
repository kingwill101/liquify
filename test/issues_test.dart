import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });

  test("issue #23", () async {
    await testParser('''
{% assign name = "hello" %}
{% if name contains "ello" %}
These shoes are awesome! {{name}}
{% endif %}
    ''', (document) {
      evaluator.evaluateNodes(document.children);
      expect(evaluator.buffer.toString().trim(),
          equals('These shoes are awesome! hello'));
    });
  });
}
