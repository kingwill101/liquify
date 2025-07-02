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

  group('Doc Tag', () {
    group('sync evaluation', () {
      test('shows raw text', () async {
        await testParser('''{% doc %}
  Renders a message.

  @param {string} foo - A string value.
  @param {string} [bar] - An optional string value.

  @example
  {% render 'message', foo: 'Hello', bar: 'World' %}
{% enddoc %}
''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), isEmpty);
        });
      });
    });

    group('async evaluation', () {
      test('shows raw text', () async {
        await testParser('''{% doc %}
  Renders a message.

  @param {string} foo - A string value.
  @param {string} [bar] - An optional string value.

  @example
  {% render 'message', foo: 'Hello', bar: 'World' %}
{% enddoc %}
''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), isEmpty);
        });
      });
    });
  });
}
