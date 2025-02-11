import 'package:liquify/src/ast.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/registry.dart';
import 'package:test/test.dart';

void main() {
  late Evaluator evaluator;

  setUp(() {
    registerBuiltIns();
    evaluator = Evaluator(Environment());
  });

  group('Dot notation filters', () {
    group("dot notation filters sync", () {
      test('first, last and size', () {
        evaluator.context.setVariable('company', {
          'departments': {
            'engineering': {
              'employees': [
                {'name': 'Charlie', 'role': 'Developer'},
                {'name': 'Alice', 'role': 'Manager'},
                {'name': 'Bob', 'role': 'Designer'}
              ]
            }
          }
        });
        expect(
            evaluator.evaluate(MemberAccess(Identifier('company'), [
              Identifier('departments'),
              Identifier('engineering'),
              Identifier('employees'),
              Identifier('first'),
              Identifier('name'),
            ])),
            'Charlie');
        expect(
            evaluator.evaluate(MemberAccess(Identifier('company'), [
              Identifier('departments'),
              Identifier('engineering'),
              Identifier('employees'),
              Identifier('last'),
              Identifier('name'),
            ])),
            'Bob');
        expect(
            evaluator.evaluate(MemberAccess(Identifier('company'), [
              Identifier('departments'),
              Identifier('engineering'),
              Identifier('employees'),
              Identifier('size'),
            ])),
            3);
      });
    });

    group("dot notation filters async", () {
      test('first, last and size async', () async {
        evaluator.context.setVariable('company', {
          'departments': {
            'engineering': {
              'employees': [
                {'name': 'Charlie', 'role': 'Developer'},
                {'name': 'Alice', 'role': 'Manager'},
                {'name': 'Bob', 'role': 'Designer'}
              ]
            }
          }
        });
        expect(
            await evaluator.evaluateAsync(MemberAccess(Identifier('company'), [
              Identifier('departments'),
              Identifier('engineering'),
              Identifier('employees'),
              Identifier('first'),
              Identifier('name'),
            ])),
            'Charlie');
        expect(
            await evaluator.evaluateAsync(MemberAccess(Identifier('company'), [
              Identifier('departments'),
              Identifier('engineering'),
              Identifier('employees'),
              Identifier('last'),
              Identifier('name'),
            ])),
            'Bob');
        expect(
            await evaluator.evaluateAsync(MemberAccess(Identifier('company'), [
              Identifier('departments'),
              Identifier('engineering'),
              Identifier('employees'),
              Identifier('size'),
            ])),
            3);
      });
    });
  });
  group('Evaluator', () {
    test('evaluates literals', () {
      expect(evaluator.evaluate(Literal(5, LiteralType.number)), 5);
      expect(evaluator.evaluate(Literal(true, LiteralType.boolean)), true);
      expect(evaluator.evaluate(Literal('hello', LiteralType.string)), 'hello');
    });

    test('evaluates literals asynchronously', () async {
      expect(await evaluator.evaluateAsync(Literal(5, LiteralType.number)), 5);
      expect(await evaluator.evaluateAsync(Literal(true, LiteralType.boolean)),
          true);
      expect(
          await evaluator.evaluateAsync(Literal('hello', LiteralType.string)),
          'hello');
    });

    test('evaluates empty literals on strings', () {
      expect(evaluator.evaluate(Literal('', LiteralType.string)), '');
      expect(evaluator.evaluate(Literal('', LiteralType.string)).isEmpty, true);
      expect(
          evaluator.evaluate(Literal('not empty', LiteralType.string)).isEmpty,
          false);
    });

    test('evaluates empty literals on strings asynchronously', () async {
      expect(
          await evaluator.evaluateAsync(Literal('', LiteralType.string)), '');
      expect(
          (await evaluator.evaluateAsync(Literal('', LiteralType.string)))
              .isEmpty,
          true);
      expect(
          (await evaluator
                  .evaluateAsync(Literal('not empty', LiteralType.string)))
              .isEmpty,
          false);
    });

    test('evaluates empty literals on arrays', () {
      expect(evaluator.evaluate(Literal([], LiteralType.array)), []);
      expect(evaluator.evaluate(Literal([], LiteralType.array)).isEmpty, true);
      expect(
          evaluator
              .evaluate(Literal([1, 2, 3, 4, 5], LiteralType.array))
              .isEmpty,
          false);
    });

    test('evaluates empty literals on arrays asynchronously', () async {
      expect(await evaluator.evaluateAsync(Literal([], LiteralType.array)), []);
      expect(
          (await evaluator.evaluateAsync(Literal([], LiteralType.array)))
              .isEmpty,
          true);
      expect(
          (await evaluator
                  .evaluateAsync(Literal([1, 2, 3, 4, 5], LiteralType.array)))
              .isEmpty,
          false);
    });

    test('evaluates assignment with filtered expression', () {
      final assignment = Assignment(
        Identifier('uppercased_name'),
        FilteredExpression(Literal('john', LiteralType.string),
            [Filter(Identifier('capitalize'), [])]),
      );

      evaluator.evaluate(assignment);
      expect(evaluator.evaluate(Identifier('uppercased_name')), 'John');
    });

    test('evaluates assignment with filtered expression asynchronously',
        () async {
      final assignment = Assignment(
        Identifier('uppercased_name'),
        FilteredExpression(Literal('john', LiteralType.string),
            [Filter(Identifier('capitalize'), [])]),
      );

      await evaluator.evaluateAsync(assignment);
      expect(
          await evaluator.evaluateAsync(Identifier('uppercased_name')), 'John');
    });

    test('evaluates assignment with literal value', () {
      final assignment = Assignment(
        Identifier('x'),
        Literal(42, LiteralType.number),
      );

      evaluator.evaluate(assignment);
      expect(evaluator.evaluate(Identifier('x')), 42);
    });

    test('evaluates assignment with literal value asynchronously', () async {
      final assignment = Assignment(
        Identifier('x'),
        Literal(42, LiteralType.number),
      );

      await evaluator.evaluateAsync(assignment);
      expect(await evaluator.evaluateAsync(Identifier('x')), 42);
    });

    test('evaluates assignment with identifier value', () {
      // First, set up a variable in the context
      evaluator.evaluate(Assignment(
        Identifier('y'),
        Literal(100, LiteralType.number),
      ));

      // Now, create an assignment that uses this identifier
      final assignment = Assignment(
        Identifier('z'),
        Identifier('y'),
      );

      evaluator.evaluate(assignment);
      expect(evaluator.evaluate(Identifier('z')), 100);
    });

    test('evaluates assignment with identifier value asynchronously', () async {
      // First, set up a variable in the context
      await evaluator.evaluateAsync(Assignment(
        Identifier('y'),
        Literal(100, LiteralType.number),
      ));

      // Now, create an assignment that uses this identifier
      final assignment = Assignment(
        Identifier('z'),
        Identifier('y'),
      );

      await evaluator.evaluateAsync(assignment);
      expect(await evaluator.evaluateAsync(Identifier('z')), 100);
    });

    test('evaluates assignment with complex expression', () {
      final complexAssignment = Assignment(
        Identifier('result'),
        BinaryOperation(
          Literal(5, LiteralType.number),
          '+',
          Literal(3, LiteralType.number),
        ),
      );

      evaluator.evaluate(complexAssignment);
      expect(evaluator.evaluate(Identifier('result')), 8);
    });

    test('evaluates assignment with complex expression asynchronously',
        () async {
      final complexAssignment = Assignment(
        Identifier('result'),
        BinaryOperation(
          Literal(5, LiteralType.number),
          '+',
          Literal(3, LiteralType.number),
        ),
      );

      await evaluator.evaluateAsync(complexAssignment);
      expect(await evaluator.evaluateAsync(Identifier('result')), 8);
    });

    test('evaluates binary operations', () {
      final addition = BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number));
      expect(evaluator.evaluate(addition), 5);

      final multiplication = BinaryOperation(
          Literal(4, LiteralType.number), '*', Literal(2, LiteralType.number));
      expect(evaluator.evaluate(multiplication), 8);
    });

    test('evaluates binary operations asynchronously', () async {
      final addition = BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number));
      expect(await evaluator.evaluateAsync(addition), 5);

      final multiplication = BinaryOperation(
          Literal(4, LiteralType.number), '*', Literal(2, LiteralType.number));
      expect(await evaluator.evaluateAsync(multiplication), 8);
    });

    test('evaluates unary operations', () {
      final notOperation =
          UnaryOperation('not', Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(notOperation), true);
    });

    test('evaluates unary operations asynchronously', () async {
      final notOperation =
          UnaryOperation('not', Literal(false, LiteralType.boolean));
      expect(await evaluator.evaluateAsync(notOperation), true);
    });

    test('evaluates grouped expressions', () {
      final grouped = GroupedExpression(BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number)));
      expect(evaluator.evaluate(grouped), 5);
    });

    test('evaluates grouped expressions asynchronously', () async {
      final grouped = GroupedExpression(BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number)));
      expect(await evaluator.evaluateAsync(grouped), 5);
    });

    test('evaluates assignments', () {
      final assignment =
          Assignment(Identifier('x'), Literal(10, LiteralType.number));
      evaluator.evaluate(assignment);
      expect(evaluator.evaluate(Identifier('x')), 10);
    });

    test('evaluates assignments asynchronously', () async {
      final assignment =
          Assignment(Identifier('x'), Literal(10, LiteralType.number));
      await evaluator.evaluateAsync(assignment);
      expect(await evaluator.evaluateAsync(Identifier('x')), 10);
    });

    test('evaluates member access', () {
      evaluator.evaluate(Assignment(
          MemberAccess(
            Identifier('user'),
            [Identifier('name')],
          ),
          Literal('John', LiteralType.string)));

      final memberAccess =
          MemberAccess(Identifier('user'), [Identifier('name')]);
      expect(evaluator.evaluate(memberAccess), 'John');
    });

    test('evaluates member access asynchronously', () async {
      await evaluator.evaluateAsync(Assignment(
          MemberAccess(
            Identifier('user'),
            [Identifier('name')],
          ),
          Literal('John', LiteralType.string)));

      final memberAccess =
          MemberAccess(Identifier('user'), [Identifier('name')]);
      expect(await evaluator.evaluateAsync(memberAccess), 'John');
    });

    test('evaluates text nodes', () {
      final textNode = TextNode('Hello, World!');
      expect(evaluator.evaluate(textNode), 'Hello, World!');
    });

    test('evaluates text nodes asynchronously', () async {
      final textNode = TextNode('Hello, World!');
      expect(await evaluator.evaluateAsync(textNode), 'Hello, World!');
    });

    test('evaluates variables', () {
      final variable = Variable('x', Literal(42, LiteralType.number));
      expect(evaluator.evaluate(variable), 42);
    });

    test('evaluates variables asynchronously', () async {
      final variable = Variable('x', Literal(42, LiteralType.number));
      expect(await evaluator.evaluateAsync(variable), 42);
    });

    test('evaluates complex expressions', () {
      final complexExpression = BinaryOperation(
          GroupedExpression(BinaryOperation(Literal(2, LiteralType.number), '*',
              Literal(3, LiteralType.number))),
          '+',
          Literal(4, LiteralType.number));
      expect(evaluator.evaluate(complexExpression), 10);
    });

    test('evaluates complex expressions asynchronously', () async {
      final complexExpression = BinaryOperation(
          GroupedExpression(BinaryOperation(Literal(2, LiteralType.number), '*',
              Literal(3, LiteralType.number))),
          '+',
          Literal(4, LiteralType.number));
      expect(await evaluator.evaluateAsync(complexExpression), 10);
    });

    test('applies filters', () {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), [])]);
      expect(evaluator.evaluate(filteredExpression), 'HELLO');
    });

    test('applies filters asynchronously', () async {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), [])]);
      expect(await evaluator.evaluateAsync(filteredExpression), 'HELLO');
    });

    test('applies multiple filters', () {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), []), Filter(Identifier('length'), [])]);
      expect(evaluator.evaluate(filteredExpression), 5);
    });

    test('applies multiple filters asynchronously', () async {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), []), Filter(Identifier('length'), [])]);
      expect(await evaluator.evaluateAsync(filteredExpression), 5);
    });

    test('applies filters with named arguments', () {
      FilterRegistry.register('truncate', (value, args, namedArgs) {
        final length = namedArgs['length'] ?? 5;
        return value.toString().substring(0, length);
      });

      final filteredExpression =
          FilteredExpression(Literal('hello world', LiteralType.string), [
        Filter(Identifier('truncate'), [
          NamedArgument(Identifier('length'), Literal(5, LiteralType.number))
        ])
      ]);
      expect(evaluator.evaluate(filteredExpression), 'hello');
    });

    test('applies filters with named arguments asynchronously', () async {
      FilterRegistry.register('truncate', (value, args, namedArgs) {
        final length = namedArgs['length'] ?? 5;
        return value.toString().substring(0, length);
      });

      final filteredExpression =
          FilteredExpression(Literal('hello world', LiteralType.string), [
        Filter(Identifier('truncate'), [
          NamedArgument(Identifier('length'), Literal(5, LiteralType.number))
        ])
      ]);
      expect(await evaluator.evaluateAsync(filteredExpression), 'hello');
    });
  });

  group('Context data evaluation', () {
    test('evaluates existing context data', () {
      evaluator.context.setVariable(
          'user', {'name': 'Alice', 'age': 30, 'last-name': 'Doe'});
      expect(
          evaluator
              .evaluate(MemberAccess(Identifier('user'), [Identifier('name')])),
          'Alice');
      expect(
          evaluator.evaluate(
              MemberAccess(Identifier('user'), [Identifier('last-name')])),
          'Doe');
      expect(
          evaluator
              .evaluate(MemberAccess(Identifier('user'), [Identifier('age')])),
          30);
    });

    test('evaluates existing context data asynchronously', () async {
      evaluator.context.setVariable(
          'user', {'name': 'Alice', 'age': 30, 'last-name': 'Doe'});
      expect(
          await evaluator.evaluateAsync(
              MemberAccess(Identifier('user'), [Identifier('name')])),
          'Alice');
      expect(
          await evaluator.evaluateAsync(
              MemberAccess(Identifier('user'), [Identifier('last-name')])),
          'Doe');
      expect(
          await evaluator.evaluateAsync(
              MemberAccess(Identifier('user'), [Identifier('age')])),
          30);
    });

    test('returns null for missing top-level context data', () {
      expect(evaluator.evaluate(Identifier('nonexistent')), null);
    });

    test('returns null for missing top-level context data asynchronously',
        () async {
      expect(await evaluator.evaluateAsync(Identifier('nonexistent')), null);
    });

    test('returns null for missing nested context data', () {
      evaluator.context.setVariable('user', {'name': 'Bob'});
      expect(
          evaluator
              .evaluate(MemberAccess(Identifier('user'), [Identifier('age')])),
          null);
    });

    test('returns null for missing nested context data asynchronously',
        () async {
      evaluator.context.setVariable('user', {'name': 'Bob'});
      expect(
          await evaluator.evaluateAsync(
              MemberAccess(Identifier('user'), [Identifier('age')])),
          null);
    });

    test('handles deep nested context data', () {
      evaluator.context.setVariable('company', {
        'departments': {
          'engineering': {
            'employees': [
              {'name': 'Charlie', 'role': 'Developer'}
            ]
          }
        }
      });
      expect(
          evaluator.evaluate(MemberAccess(Identifier('company'), [
            Identifier('departments'),
            Identifier('engineering'),
            ArrayAccess(
                Identifier('employees'), Literal(0, LiteralType.number)),
            Identifier('name')
          ])),
          'Charlie');
    });

    test('handles deep nested context data asynchronously', () async {
      evaluator.context.setVariable('company', {
        'departments': {
          'engineering': {
            'employees': [
              {'name': 'Charlie', 'role': 'Developer'}
            ]
          }
        }
      });
      expect(
          await evaluator.evaluateAsync(MemberAccess(Identifier('company'), [
            Identifier('departments'),
            Identifier('engineering'),
            ArrayAccess(
                Identifier('employees'), Literal(0, LiteralType.number)),
            Identifier('name')
          ])),
          'Charlie');
    });

    test('returns null for partially missing deep nested context data', () {
      evaluator.context.setVariable('company', {
        'departments': {'engineering': {}}
      });
      expect(
          evaluator.evaluate(MemberAccess(Identifier('company'), [
            Identifier('departments'),
            Identifier('engineering'),
            ArrayAccess(
              Identifier('employees'),
              Literal(0, LiteralType.number),
            ),
            Identifier('name')
          ])),
          null);
    });

    test(
        'returns null for partially missing deep nested context data asynchronously',
        () async {
      evaluator.context.setVariable('company', {
        'departments': {'engineering': {}}
      });
      expect(
          await evaluator.evaluateAsync(MemberAccess(Identifier('company'), [
            Identifier('departments'),
            Identifier('engineering'),
            ArrayAccess(
              Identifier('employees'),
              Literal(0, LiteralType.number),
            ),
            Identifier('name')
          ])),
          null);
    });

    test('evaluate array int access', () {
      evaluator.context.setVariable('numbers', [1, 2, 3, 4, 5]);
      expect(
          evaluator.evaluate(ArrayAccess(
            Identifier('numbers'),
            Literal(0, LiteralType.number),
          )),
          1);
    });

    test('evaluate array int access asynchronously', () async {
      evaluator.context.setVariable('numbers', [1, 2, 3, 4, 5]);
      expect(
          await evaluator.evaluateAsync(ArrayAccess(
            Identifier('numbers'),
            Literal(0, LiteralType.number),
          )),
          1);
    });

    test('evaluate array string access', () {
      evaluator.context.setVariable('name', {
        'first': 'John',
      });
      expect(
          evaluator.evaluate(ArrayAccess(
            Identifier('name'),
            Literal('first', LiteralType.string),
          )),
          equals('John'));
    });

    test('evaluate array string access asynchronously', () async {
      evaluator.context.setVariable('name', {
        'first': 'John',
      });
      expect(
          await evaluator.evaluateAsync(ArrayAccess(
            Identifier('name'),
            Literal('first', LiteralType.string),
          )),
          equals('John'));
    });
  });
}
