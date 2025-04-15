import 'package:liquify/src/ast.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/registry.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    registerBuiltIns();
    evaluator = Evaluator(Environment());
  });

  tearDown(() {
    evaluator.context.clear();
  });

  group('Arithmetic operators', () {
    test('Addition operator (+)', () {
      final addition = BinaryOperation(
          Literal(5, LiteralType.number), '+', Literal(3, LiteralType.number));
      expect(evaluator.evaluate(addition), 8);
    });

    test('Subtraction operator (-)', () {
      final subtraction = BinaryOperation(
          Literal(10, LiteralType.number), '-', Literal(4, LiteralType.number));
      expect(evaluator.evaluate(subtraction), 6);
    });

    test('Multiplication operator (*)', () {
      final multiplication = BinaryOperation(
          Literal(6, LiteralType.number), '*', Literal(7, LiteralType.number));
      expect(evaluator.evaluate(multiplication), 42);
    });

    test('Division operator (/)', () {
      final division = BinaryOperation(
          Literal(20, LiteralType.number), '/', Literal(4, LiteralType.number));
      expect(evaluator.evaluate(division), 5);
    });

    test('Addition with null values', () {
      final nullAddition = BinaryOperation(
          Literal(null, LiteralType.nil), '+', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(nullAddition), 5);
    });

    test('Multiplication with null values', () {
      final nullMultiplication = BinaryOperation(
          Literal(null, LiteralType.nil), '*', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(nullMultiplication), 5);
    });
  });

  group('Comparison operators', () {
    test('Equal operator (==)', () {
      final equalTrue = BinaryOperation(
          Literal(5, LiteralType.number), '==', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(equalTrue), true);

      final equalFalse = BinaryOperation(
          Literal(5, LiteralType.number), '==', Literal(6, LiteralType.number));
      expect(evaluator.evaluate(equalFalse), false);
    });

    test('Not equal operator (!=)', () {
      final notEqualTrue = BinaryOperation(
          Literal(5, LiteralType.number), '!=', Literal(6, LiteralType.number));
      expect(evaluator.evaluate(notEqualTrue), true);

      final notEqualFalse = BinaryOperation(
          Literal(5, LiteralType.number), '!=', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(notEqualFalse), false);
    });

    test('Greater than operator (>)', () {
      final greaterThanTrue = BinaryOperation(
          Literal(10, LiteralType.number), '>', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(greaterThanTrue), true);

      final greaterThanFalse = BinaryOperation(
          Literal(5, LiteralType.number), '>', Literal(10, LiteralType.number));
      expect(evaluator.evaluate(greaterThanFalse), false);
    });

    test('Less than operator (<)', () {
      final lessThanTrue = BinaryOperation(
          Literal(5, LiteralType.number), '<', Literal(10, LiteralType.number));
      expect(evaluator.evaluate(lessThanTrue), true);

      final lessThanFalse = BinaryOperation(
          Literal(10, LiteralType.number), '<', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(lessThanFalse), false);
    });

    test('Greater than or equal operator (>=)', () {
      final greaterEqualTrue1 = BinaryOperation(Literal(10, LiteralType.number),
          '>=', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(greaterEqualTrue1), true);

      final greaterEqualTrue2 = BinaryOperation(
          Literal(5, LiteralType.number), '>=', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(greaterEqualTrue2), true);

      final greaterEqualFalse = BinaryOperation(Literal(5, LiteralType.number),
          '>=', Literal(10, LiteralType.number));
      expect(evaluator.evaluate(greaterEqualFalse), false);
    });

    test('Less than or equal operator (<=)', () {
      final lessEqualTrue1 = BinaryOperation(Literal(5, LiteralType.number),
          '<=', Literal(10, LiteralType.number));
      expect(evaluator.evaluate(lessEqualTrue1), true);

      final lessEqualTrue2 = BinaryOperation(
          Literal(5, LiteralType.number), '<=', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(lessEqualTrue2), true);

      final lessEqualFalse = BinaryOperation(Literal(10, LiteralType.number),
          '<=', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(lessEqualFalse), false);
    });

    test('Comparison with null values', () {
      final nullComparison = BinaryOperation(
          Literal(null, LiteralType.nil), '<', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(nullComparison), true);
    });
  });

  group('Logical operators', () {
    test('AND operator', () {
      final andTrue = BinaryOperation(Literal(true, LiteralType.boolean), 'and',
          Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(andTrue), true);

      final andFalse1 = BinaryOperation(Literal(true, LiteralType.boolean),
          'and', Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(andFalse1), false);

      final andFalse2 = BinaryOperation(Literal(false, LiteralType.boolean),
          'and', Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(andFalse2), false);

      final andFalse3 = BinaryOperation(Literal(false, LiteralType.boolean),
          'and', Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(andFalse3), false);
    });

    test('OR operator', () {
      final orTrue1 = BinaryOperation(Literal(true, LiteralType.boolean), 'or',
          Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(orTrue1), true);

      final orTrue2 = BinaryOperation(Literal(true, LiteralType.boolean), 'or',
          Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(orTrue2), true);

      final orTrue3 = BinaryOperation(Literal(false, LiteralType.boolean), 'or',
          Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(orTrue3), true);

      final orFalse = BinaryOperation(Literal(false, LiteralType.boolean), 'or',
          Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(orFalse), false);
    });

    test('NOT operator', () {
      final notTrue =
          UnaryOperation('not', Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(notTrue), true);

      final notFalse =
          UnaryOperation('not', Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(notFalse), false);
    });

    test('Exclamation NOT operator', () {
      final notTrue = UnaryOperation('!', Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(notTrue), true);

      final notFalse = UnaryOperation('!', Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(notFalse), false);
    });

    test('Truthy values in logical operators', () {
      // Non-empty string is truthy
      final truthyString = BinaryOperation(Literal('hello', LiteralType.string),
          'and', Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(truthyString), true);

      // Non-zero number is truthy
      final truthyNumber = BinaryOperation(Literal(42, LiteralType.number),
          'and', Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(truthyNumber), true);

      final falsyString = BinaryOperation(Literal('', LiteralType.string),
          'and', Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(falsyString), true);

      // Zero is falsy
      final falsyNumber = BinaryOperation(Literal(0, LiteralType.number), 'and',
          Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(falsyNumber), true);

      // Null is falsy
      final falsyNull = BinaryOperation(Literal(null, LiteralType.nil), 'and',
          Literal(true, LiteralType.boolean));
      expect(evaluator.evaluate(falsyNull), false);
    });
  });

  group('Range operator', () {
    test('Range operator (..)', () {
      final range = BinaryOperation(
          Literal(1, LiteralType.number), '..', Literal(5, LiteralType.number));
      expect(evaluator.evaluate(range), [1, 2, 3, 4, 5]);
    });

    test('Range with null values', () {
      final nullRange = BinaryOperation(
          Literal(null, LiteralType.nil), '..', Literal(3, LiteralType.number));
      expect(evaluator.evaluate(nullRange), [0, 1, 2, 3]);
    });
  });

  group('Containment operators', () {
    test('Contains operator with strings', () {
      final containsTrue = BinaryOperation(
          Literal('hello world', LiteralType.string),
          'contains',
          Literal('world', LiteralType.string));
      expect(evaluator.evaluate(containsTrue), true);

      final containsFalse = BinaryOperation(
          Literal('hello world', LiteralType.string),
          'contains',
          Literal('universe', LiteralType.string));
      expect(evaluator.evaluate(containsFalse), false);
    });
    test('Contains operator with arrays', () {
      final containsTrue = BinaryOperation(
          Literal('1,2,3,4,5', LiteralType.string),
          'contains',
          Literal('3', LiteralType.string));
      expect(evaluator.evaluate(containsTrue), true);

      final containsFalse = BinaryOperation(
          Literal('1,2,3,4,5', LiteralType.string),
          'contains',
          Literal('6', LiteralType.string));
      expect(evaluator.evaluate(containsFalse), false);
    });

    test('In operator', () {
      final array = Literal([1, 2, 3, 4, 5], LiteralType.array);

      final inTrue =
          BinaryOperation(Literal(3, LiteralType.number), 'in', array);
      expect(evaluator.evaluate(inTrue), true);

      final inFalse =
          BinaryOperation(Literal(6, LiteralType.number), 'in', array);
      expect(evaluator.evaluate(inFalse), false);
    });
  });

  group('Operator precedence', () {
    test('Multiplication has higher precedence than addition', () {
      // 2 + 3 * 4 should be 2 + (3 * 4) = 2 + 12 = 14
      final expression = BinaryOperation(
          Literal(2, LiteralType.number),
          '+',
          BinaryOperation(Literal(3, LiteralType.number), '*',
              Literal(4, LiteralType.number)));
      expect(evaluator.evaluate(expression), 14);
    });

    test('Parentheses override operator precedence', () {
      // (2 + 3) * 4 should be 5 * 4 = 20
      final expression = BinaryOperation(
          GroupedExpression(BinaryOperation(Literal(2, LiteralType.number), '+',
              Literal(3, LiteralType.number))),
          '*',
          Literal(4, LiteralType.number));
      expect(evaluator.evaluate(expression), 20);
    });
  });

  group('Operators with variables', () {
    test('Arithmetic with variables', () async {
      await testParser('{% assign x = 10 %}{% assign y = 5 %}{{ x + y }}',
          (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), '15');
      });
    });

    test('Comparison with variables', () async {
      await testParser('{% assign x = 10 %}{% assign y = 5 %}{{ x > y }}',
          (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), 'true');
      });
    });

    test('Logical operators with variables', () async {
      await testParser(
          '{% assign x = true %}{% assign y = false %}{{ x and y }}',
          (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), 'false');
      });
    });
  });

  group('Operators in conditional statements', () {
    test('Comparison in if statements', () async {
      await testParser('''
        {% assign x = 10 %}
        {% if x > 5 %}
          Greater
        {% else %}
          Lesser
        {% endif %}
      ''', (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString().trim(), 'Greater');
      });
    });

    test('Logical operators in if statements', () async {
      await testParser('''
        {% assign x = 10 %}
        {% assign y = 5 %}
        {% if x > 5 and y < 10 %}
          Both conditions met
        {% else %}
          Conditions not met
        {% endif %}
      ''', (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString().trim(), 'Both conditions met');
      });
    });

    test('Contains operator in if statements', () async {
      await testParser('''
        {% assign fruits = "apple,banana,orange" | split: "," %}
        {% if fruits contains "banana" %}
          Found banana
        {% else %}
          No banana
        {% endif %}
      ''', (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString().trim(), 'Found banana');
      });
    });
  });

  group('Complex operator expressions', () {
    test('Mixed operator types', () async {
      await testParser('{% assign x = 5 %}{{ x > 3 and x < 10 }}', (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), 'true');
      });
    });
  });

  group('Edge cases', () {
    test('Division by zero', () async {
      await testParser('{{ 10 / 0 }}', (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), 'Infinity');
      });
    });
  });

  group('Operator chaining', () {
    test('Chained comparison operators', () async {
      await testParser('{% assign x = 5 %}{{ x > 3 and x < 10 }}', (document) {
        evaluator.evaluateNodes(document.children);
        expect(evaluator.buffer.toString(), 'true');
      });
    });

    group('String operations', () {
      test('String concatenation with plus operator', () async {
        await testParser('{{ "Hello, " + "World!" }}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'Hello, World!');
        });
      });

      test('String and number concatenation', () async {
        await testParser('{{ "The answer is: " + 42 }}', (document) {
          evaluator.evaluateNodes(document.children);
          expect(evaluator.buffer.toString(), 'The answer is: 42');
        });
      });
    });

    group('Async operator evaluation', () {
      test('Arithmetic operators async', () async {
        final addition = BinaryOperation(Literal(5, LiteralType.number), '+',
            Literal(3, LiteralType.number));
        expect(await evaluator.evaluateAsync(addition), 8);
      });

      test('Comparison operators async', () async {
        final equalTrue = BinaryOperation(Literal(5, LiteralType.number), '==',
            Literal(5, LiteralType.number));
        expect(await evaluator.evaluateAsync(equalTrue), true);
      });

      test('Logical operators async', () async {
        final andTrue = BinaryOperation(Literal(true, LiteralType.boolean),
            'and', Literal(true, LiteralType.boolean));
        expect(await evaluator.evaluateAsync(andTrue), true);
      });

      test('Range operator async', () async {
        final range = BinaryOperation(Literal(1, LiteralType.number), '..',
            Literal(5, LiteralType.number));
        expect(await evaluator.evaluateAsync(range), [1, 2, 3, 4, 5]);
      });

      test('Contains operator async', () async {
        final containsTrue = BinaryOperation(
            Literal('hello world', LiteralType.string),
            'contains',
            Literal('world', LiteralType.string));
        expect(await evaluator.evaluateAsync(containsTrue), true);
      });
    });
  });
}
