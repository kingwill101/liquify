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
    group('sync evaluation', () {
      test('shows raw text', () async {
        await testParser('''{% raw %}{% liquid
assign my_variable = "string"
%}{% endraw %}''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '''{% liquid
assign my_variable = "string"
%}''');
        });
      });

      test('preserves liquid tags', () async {
        await testParser('''{% raw %}
{% if user %}
  Hello {{ user.name }}!
{% endif %}{% endraw %}''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), '''{% if user %}
  Hello {{ user.name }}!
{% endif %}''');
        });
      });
    });

    group('async evaluation', () {
      test('shows raw text', () async {
        await testParser('''{% raw %}{% liquid
assign my_variable = "string"
%}{% endraw %}''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '''{% liquid
assign my_variable = "string"
%}''');
        });
      });

      test('preserves liquid tags', () async {
        await testParser('''{% raw %}
{% if user %}
  Hello {{ user.name }}!
{% endif %}{% endraw %}''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), '''{% if user %}
  Hello {{ user.name }}!
{% endif %}''');
        });
      });
    });
  });
}
