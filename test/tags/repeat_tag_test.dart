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

  group('RepeatTag', () {
    group('sync evaluation', () {
      test('repeats content given number of times', () async {
        await testParser('{% repeat 3 %}hello{% endrepeat %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'hello hello hello');
        });
      });

      test('repeats with variable', () async {
        await testParser('''
          {% assign times = 2 %}
          {% repeat times %}world {% endrepeat %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), 'world world');
        });
      });

      test('repeats with filters', () async {
        await testParser(
          '{% repeat 3 | upcase %}hi {% endrepeat  %}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'HI HI HI');
          });
      });

      test('repeats with multiple filters', () async {
        await testParser(
          '{% repeat 2 | upcase | append: "!"%}test {% endrepeat  %}',
          (document) {
            evaluator.evaluateNodes(document.children);
            expect(evaluator.buffer.toString(), 'TEST TEST!');
          });
      });
    });

    group('async evaluation', () {
      test('repeats content given number of times', () async {
        await testParser('{% repeat 3 %}'
            'hello'
            '{% endrepeat %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'hello hello hello');
        });
      });

      test('repeats with variable', () async {
        await testParser('''
          {% assign times = 2 %}
          {% repeat times %}world {% endrepeat %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), 'world world');
        });
      });

      test('repeats with filters', () async {
        await testParser(
          '{% repeat 3 | upcase %}hi {% endrepeat  %}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'HI HI HI');
          });
      });

      test('repeats with multiple filters', () async {
        await testParser(
          '{% repeat 2 | upcase | append: "!"  %}test {% endrepeat %}',
          (document) async {
            await evaluator.evaluateNodesAsync(document.children);
            expect(evaluator.buffer.toString(), 'TEST TEST!');
          });
      });
    });
  });
}