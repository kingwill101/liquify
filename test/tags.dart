import 'package:liquid_grammar/context.dart';
import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/grammar.dart';
import 'package:liquid_grammar/registry.dart';
import 'package:petitparser/core.dart';
import 'package:test/test.dart';

void main() {
  final evaluator = Evaluator(Environment());
  final parser = LiquidGrammar().build();

  setUp(() {
    registerBuiltIns();
  });

  group('ForTag', () {
    test('basic iteration', () {
      final result =
          parser.parse('{% for item in (1..3) %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '123');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('else block', () {
      final result = parser.parse(
          '{% for item in (1..0) %}{{ item }}{% else %}No items{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'No items');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('break tag', () {
      final result = parser.parse(
          '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('continue tag', () {
      final result = parser.parse(
          '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('limit filter', () {
      final result = parser
          .parse('{% for item in (1..5) limit:3 %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '123');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('offset filter', () {
      final result = parser
          .parse('{% for item in (1..5) offset:2 %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '345');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('reversed filter', () {
      final result = parser
          .parse('{% for item in (1..3) reversed %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '321');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });

  group('IfTag', () {
    test('basic if statement', () {
      final result = parser.parse('{% if true %}True{% endif %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'True');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('if-else statement', () {
      final result =
          parser.parse('{% if false %}True{% else %}False{% endif %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'False');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('nested if statements', () {
      final result = parser.parse(
          '{% if true %}{% if false %}Inner False{% else %}Inner True{% endif %}{% endif %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), 'Inner True');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('if statement with break', () {
      final result = parser.parse(
          '{% for item in (1..5) %}{% if item == 3 %}{% break %}{% endif %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '12');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });

    test('if statement with continue', () {
      final result = parser.parse(
          '{% for item in (1..5) %}{% if item == 3 %}{% continue %}{% endif %}{{ item }}{% endfor %}');
      if (result is Success) {
        final document = result.value;
        evaluator.evaluate(document);
        expect(evaluator.buffer.toString(), '1245');
      } else {
        fail('Parsing failed: ${result.message}');
      }
    });
  });
}
