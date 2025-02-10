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

  group('IfTag', () {
    group('sync evaluation', () {
      test('basic if statement', () async {
        await testParser('{% if true %}True{% endif %}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'True');
        });
      });

      test('if-else statement', () async {
        await testParser('{% if false %}True{% else %}False{% endif %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'False');
        });
      });

      test('nested if statements', () async {
        await testParser(
            '{% if true %}{% if false %}Inner False{% else %}Inner True{% endif %}{% endif %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Inner True');
        });
      });

      test('if statement with break', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '12');
        });
      });

      test('if statement with continue', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}',
            (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), '1245');
        });
      });

      test('if with multiple elseifs', () async {
        await testParser('''
          {% if false %}
            first
          {% elseif true %}
            second
          {% elseif true %}
            third
          {% else %}
            fourth
          {% endif %}
        ''', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString().trim(), 'second');
        });
      });
    });

    group('async evaluation', () {
      test('basic if statement', () async {
        await testParser('{% if true %}True{% endif %}', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'True');
        });
      });

      test('if-else statement', () async {
        await testParser('{% if false %}True{% else %}False{% endif %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'False');
        });
      });

      test('nested if statements', () async {
        await testParser(
            '{% if true %}{% if false %}Inner False{% else %}Inner True{% endif %}{% endif %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), 'Inner True');
        });
      });

      test('if statement with break', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '12');
        });
      });

      test('if statement with continue', () async {
        await testParser(
            '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}',
            (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString(), '1245');
        });
      });

      test('if with multiple elseifs', () async {
        await testParser('''
          {% if false %}
            first
          {% elseif true %}
            second
          {% elseif true %}
            third
          {% else %}
            fourth
          {% endif %}
        ''', (document) async {
          await evaluator.evaluateNodesAsync(document.children);
          expect(evaluator.buffer.toString().trim(), 'second');
        });
      });
    });
  });
}
