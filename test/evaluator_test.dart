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

  group('Evaluator', () {
    group('Literal evaluation', () {
      test('evaluates number literals', () async {
        expect(await evaluator.evaluate(Literal(42, LiteralType.number)), 42);
        expect(await evaluator.evaluate(Literal(-17, LiteralType.number)), -17);
        expect(
            await evaluator.evaluate(Literal(3.14, LiteralType.number)), 3.14);
        expect(await evaluator.evaluate(Literal(0, LiteralType.number)), 0);
      });

      test('evaluates string literals', () async {
        expect(await evaluator.evaluate(Literal('hello', LiteralType.string)),
            'hello');
        expect(await evaluator.evaluate(Literal('', LiteralType.string)), '');
        expect(await evaluator.evaluate(Literal('123', LiteralType.string)),
            '123');
        expect(
            await evaluator.evaluate(Literal(' spaces ', LiteralType.string)),
            ' spaces ');
      });

      test('evaluates boolean literals', () async {
        expect(
            await evaluator.evaluate(Literal(true, LiteralType.boolean)), true);
        expect(await evaluator.evaluate(Literal(false, LiteralType.boolean)),
            false);
      });

      test('evaluates array literals', () async {
        expect(await evaluator.evaluate(Literal([], LiteralType.array)), []);
        expect(await evaluator.evaluate(Literal([1, 2, 3], LiteralType.array)),
            [1, 2, 3]);
        expect(
            await evaluator
                .evaluate(Literal(['a', 'b', 'c'], LiteralType.array)),
            ['a', 'b', 'c']);
      });

      test('evaluates nil literal', () async {
        expect(await evaluator.evaluate(Literal(null, LiteralType.nil)), null);
      });

      test('evaluates empty literal', () async {
        final emptyLit =
            await evaluator.evaluate(Literal(Empty(), LiteralType.empty));
        expect(emptyLit, isA<Empty>());
        expect(
            emptyLit == '', true); // Empty should compare equal to empty string
        expect(
            emptyLit == [], true); // Empty should compare equal to empty array
      });

      test('literal type matches value type', () async {
        final numLit =
            await evaluator.evaluate(Literal(42, LiteralType.number));
        expect(numLit, isA<num>());

        final strLit =
            await evaluator.evaluate(Literal('hello', LiteralType.string));
        expect(strLit, isA<String>());

        final boolLit =
            await evaluator.evaluate(Literal(true, LiteralType.boolean));
        expect(boolLit, isA<bool>());

        final arrayLit =
            await evaluator.evaluate(Literal([1, 2, 3], LiteralType.array));
        expect(arrayLit, isA<List>());
      });
    });
    test('evaluates literals', () async {
      expect(await evaluator.evaluate(Literal(5, LiteralType.number)), 5);
      expect(
          await evaluator.evaluate(Literal(true, LiteralType.boolean)), true);
      expect(await evaluator.evaluate(Literal('hello', LiteralType.string)),
          'hello');
    });

    test('evaluates empty literals on strings', () async {
      expect(await evaluator.evaluate(Literal('', LiteralType.string)), '');
      expect(
          (await evaluator.evaluate(Literal('', LiteralType.string))).isEmpty,
          true);
      expect(
          (await evaluator.evaluate(Literal('not empty', LiteralType.string)))
              .isEmpty,
          false);
    });

    test('evaluates empty literals on arrays', () async {
      expect(await evaluator.evaluate(Literal([], LiteralType.array)), []);
      expect((await evaluator.evaluate(Literal([], LiteralType.array))).isEmpty,
          true);
      expect(
          (await evaluator
                  .evaluate(Literal([1, 2, 3, 4, 5], LiteralType.array)))
              .isEmpty,
          false);
    });

    test('evaluates assignment with filtered expression', () async {
      final assignment = Assignment(
        Identifier('uppercased_name'),
        FilteredExpression(Literal('john', LiteralType.string),
            [Filter(Identifier('capitalize'), [])]),
      );

      await evaluator.evaluate(assignment);
      expect(await evaluator.evaluate(Identifier('uppercased_name')), 'John');
    });

    test('evaluates assignment with literal value', () async {
      final assignment = Assignment(
        Identifier('x'),
        Literal(42, LiteralType.number),
      );

      await evaluator.evaluate(assignment);
      expect(await evaluator.evaluate(Identifier('x')), 42);
    });

    test('evaluates assignment with identifier value', () async {
      // First, set up a variable in the context
      await evaluator.evaluate(Assignment(
        Identifier('y'),
        Literal(100, LiteralType.number),
      ));

      // Now, create an assignment that uses this identifier
      final assignment = Assignment(
        Identifier('z'),
        Identifier('y'),
      );

      await evaluator.evaluate(assignment);
      expect(await evaluator.evaluate(Identifier('z')), 100);
    });

    test('evaluates assignment with complex expression', () async {
      final complexAssignment = Assignment(
        Identifier('result'),
        BinaryOperation(
          Literal(5, LiteralType.number),
          '+',
          Literal(3, LiteralType.number),
        ),
      );

      await evaluator.evaluate(complexAssignment);
      expect(await evaluator.evaluate(Identifier('result')), 8);
    });

    test('evaluates binary operations', () async {
      final addition = BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number));
      expect(await evaluator.evaluate(addition), 5);

      final multiplication = BinaryOperation(
          Literal(4, LiteralType.number), '*', Literal(2, LiteralType.number));
      expect(await evaluator.evaluate(multiplication), 8);
    });

    test('evaluates unary operations', () async {
      final notOperation =
          UnaryOperation('not', Literal(false, LiteralType.boolean));
      expect(await evaluator.evaluate(notOperation), true);
    });

    test('evaluates grouped expressions', () async {
      final grouped = GroupedExpression(BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number)));
      expect(await evaluator.evaluate(grouped), 5);
    });

    test('evaluates assignments', () async {
      final assignment =
          Assignment(Identifier('x'), Literal(10, LiteralType.number));
      await evaluator.evaluate(assignment);
      expect(await evaluator.evaluate(Identifier('x')), 10);
    });

    test('evaluates member access', () async {
      await evaluator.evaluate(Assignment(
          MemberAccess(
            Identifier('user'),
            [Identifier('name')],
          ),
          Literal('John', LiteralType.string)));

      final memberAccess =
          MemberAccess(Identifier('user'), [Identifier('name')]);
      expect(await evaluator.evaluate(memberAccess), 'John');
    });

    test('evaluates text nodes', () async {
      final textNode = TextNode('Hello, World!');
      expect(await evaluator.evaluate(textNode), 'Hello, World!');
    });

    test('evaluates variables', () async {
      final variable = Variable('x', Literal(42, LiteralType.number));
      expect(await evaluator.evaluate(variable), 42);
    });

    test('evaluates complex expressions', () async {
      final complexExpression = BinaryOperation(
          GroupedExpression(BinaryOperation(Literal(2, LiteralType.number), '*',
              Literal(3, LiteralType.number))),
          '+',
          Literal(4, LiteralType.number));
      expect(await evaluator.evaluate(complexExpression), 10);
    });

    test('applies filters', () async {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), [])]);
      expect(await evaluator.evaluate(filteredExpression), 'HELLO');
    });

    test('applies multiple filters', () async {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), []), Filter(Identifier('length'), [])]);
      expect(await evaluator.evaluate(filteredExpression), 5);
    });

    test('applies filters with named arguments', () async {
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
      expect(await evaluator.evaluate(filteredExpression), 'hello');
    });
  });

  group('Context data evaluation', () {
    test('evaluates existing context data', () async {
      evaluator.context.setVariable(
          'user', {'name': 'Alice', 'age': 30, 'last-name': 'Doe'});
      expect(
          await evaluator
              .evaluate(MemberAccess(Identifier('user'), [Identifier('name')])),
          'Alice');
      expect(
          await evaluator.evaluate(
              MemberAccess(Identifier('user'), [Identifier('last-name')])),
          'Doe');
      expect(
          await evaluator
              .evaluate(MemberAccess(Identifier('user'), [Identifier('age')])),
          30);
    });

    test('returns null for missing top-level context data', () async {
      expect(await evaluator.evaluate(Identifier('nonexistent')), null);
    });

    test('returns null for missing nested context data', () async {
      evaluator.context.setVariable('user', {'name': 'Bob'});
      expect(
          await evaluator
              .evaluate(MemberAccess(Identifier('user'), [Identifier('age')])),
          null);
    });

    test('handles deep nested context data', () async {
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
          await evaluator.evaluate(MemberAccess(Identifier('company'), [
            Identifier('departments'),
            Identifier('engineering'),
            ArrayAccess(
                Identifier('employees'), Literal(0, LiteralType.number)),
            Identifier('name')
          ])),
          'Charlie');
    });

    test('returns null for partially missing deep nested context data',
        () async {
      evaluator.context.setVariable('company', {
        'departments': {'engineering': {}}
      });
      expect(
          await evaluator.evaluate(MemberAccess(Identifier('company'), [
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

    test('evaluate array int access', () async {
      evaluator.context.setVariable('numbers', [1, 2, 3, 4, 5]);
      expect(
          await evaluator.evaluate(ArrayAccess(
            Identifier('numbers'),
            Literal(0, LiteralType.number),
          )),
          1);
    });
    test('evaluate array string access', () async {
      evaluator.context.setVariable('name', {
        'first': 'John',
      });
      expect(
          await evaluator.evaluate(ArrayAccess(
            Identifier('name'),
            Literal('first', LiteralType.string),
          )),
          equals('John'));
    });
  });
}
