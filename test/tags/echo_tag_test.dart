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

  group('EchoTag', () {
    group('sync evaluation', () {
      test('echoes variable with filter', () async {
        await testParser('''
          {% assign username = "Bob" %}
          {% echo username | append: ", welcome to LiquidJS!" %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(
              evaluator.buffer.toString().trim(), 'Bob, welcome to LiquidJS!');
        });
      });

      test('echoes variable with multiple filters', () async {
        await testParser('''
          {% assign name = "bob" %}
          {% echo name | capitalize | append: ", hello!" %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), 'Bob, hello!');
        });
      });

      test('echoes string with filters', () async {
        await testParser('''
          {% echo "hello world" | split: " " | first | capitalize %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), 'Hello');
        });
      });
    });

    group('async evaluation', () {
      test('echoes variable with filter', () async {
        await testParser('''
          {% assign username = "Bob" %}
          {% echo username | append: ", welcome to LiquidJS!" %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(
              evaluator.buffer.toString().trim(), 'Bob, welcome to LiquidJS!');
        });
      });

      test('echoes variable with multiple filters', () async {
        await testParser('''
          {% assign name = "bob" %}
          {% echo name | capitalize | append: ", hello!" %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), 'Bob, hello!');
        });
      });

      test('echoes string with filters', () async {
        await testParser('''
          {% echo "hello world" | split: " " | first | capitalize %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), 'Hello');
        });
      });
    });
  });
}
