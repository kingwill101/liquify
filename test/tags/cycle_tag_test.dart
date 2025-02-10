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
    group('sync evaluation', () {
      test('basic cycling through values', () async {
        await testParser(
            '{% cycle "one", "two", "three" %}'
            '{% cycle "one", "two", "three" %}'
            '{% cycle "one", "two", "three" %}'
            '{% cycle "one", "two", "three" %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'onetwothreeone');
        });
      });

      test('cycling with named groups', () async {
        await testParser(
            '{% cycle "group1": "one", "two", "three" %}'
            '{% cycle "group2": "a", "b", "c" %}'
            '{% cycle "group1": "one", "two", "three" %}'
            '{% cycle "group2": "a", "b", "c" %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'oneatwob');
        });
      });

      test('cycling with variables', () async {
        await testParser(
            '{% assign var1 = "first" %}'
            '{% assign var2 = "second" %}'
            '{% cycle var1, var2 %}'
            '{% cycle var1, var2 %}'
            '{% cycle var1, var2 %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'firstsecondfirst');
        });
      });
    });

    group('async evaluation', () {
      test('basic cycling through values', () async {
        await testParser(
            '{% cycle "one", "two", "three" %}'
            '{% cycle "one", "two", "three" %}'
            '{% cycle "one", "two", "three" %}'
            '{% cycle "one", "two", "three" %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'onetwothreeone');
        });
      });

      test('cycling with named groups', () async {
        await testParser(
            '{% cycle "group1": "one", "two", "three" %}'
            '{% cycle "group2": "a", "b", "c" %}'
            '{% cycle "group1": "one", "two", "three" %}'
            '{% cycle "group2": "a", "b", "c" %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'oneatwob');
        });
      });

      test('cycling with variables', () async {
        await testParser(
            '{% assign var1 = "first" %}'
            '{% assign var2 = "second" %}'
            '{% cycle var1, var2 %}'
            '{% cycle var1, var2 %}'
            '{% cycle var1, var2 %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'firstsecondfirst');
        });
      });
    });
  });
}
