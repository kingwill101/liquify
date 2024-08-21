import 'dart:convert';

import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/grammar.dart';
import 'package:liquid_grammar/util.dart';
import 'package:petitparser/debug.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('Liquid Grammar Parser', () {
    test('Parses liquid tags', () {
      testParser('''
{% liquid
 assign my_variable = "string"
%}''', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'liquid');
        expect(tag.content.length, 2);
        expect((tag.content[0] as Tag).name, 'assign');
      });
    });

    test('Parses raw tags', () {
      testParser('''
{% raw %}
 assign my_variable = "string"
{% endraw %}''', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'raw');
        expect(tag.content.length, 1);
      });
    });

    test('Parses complex tags', () {
      testParser('''
{% if user.logged_in %}
  <p>Welcome back, {{ user.name }}!</p>
  {% if user.admin %}
  <p>You are an admin!</p>
  {% endif %}
  {% assign my_variable = "string" %}
 {% else %}
 <p>Please log in.</p>
 {% raw %}
    {{{ }}}  {{f sdfad }}
    {{{ }}}}}}
 {% endraw %}
{% endif %}
''', (document) {
        expect(document.children.length, greaterThan(0));
      });
    });

    test('Parses simple variable expression', () {
      testParser('{{ user }}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        expect((variable.expression as Identifier).name, 'user');
      });
    });
    test('Parses variable expression with filters', () {
      testParser('{{ user | filter1 | filter2 }}', (document) {
        expect(document.children.length, 1);

        final filtered = document.children[0] as FilteredExpression;

        expect(filtered.expression, isA<Variable>());

        final variable = filtered.expression as Variable;
        expect((variable.expression as Identifier).name, 'user');
        expect(filtered.filters.length, 2);
        expect(filtered.filters[0].name.name, 'filter1');
        expect(filtered.filters[1].name.name, 'filter2');
      });
    });

    test('Parses variable expression with filter arguments', () {
      testParser('{{ user | filter1: var1,var2 | filter2: var3:3, var4:4 }}',
          (document) {
        expect(document.children.length, 1);

        final filtered = document.children[0] as FilteredExpression;

        expect(filtered.expression, isA<Variable>());
        final variable = filtered.expression as Variable;
        expect((variable.expression as Identifier).name, 'user');

        expect(filtered.filters.length, 2);

        expect(filtered.filters[0].name.name, 'filter1');
        expect(filtered.filters[0].arguments.length, 2);
        expect((filtered.filters[0].arguments[0] as Identifier).name, 'var1');
        expect((filtered.filters[0].arguments[1] as Identifier).name, 'var2');

        expect(filtered.filters[1].name.name, 'filter2');
        expect(filtered.filters[1].arguments.length, 2);
        expect((filtered.filters[1].arguments[0] as NamedArgument).name.name,
            'var3');
        expect(
            ((filtered.filters[1].arguments[0] as NamedArgument).value
                    as Literal)
                .value,
            3);
        expect((filtered.filters[1].arguments[1] as NamedArgument).name.name,
            'var4');
        expect(
            ((filtered.filters[1].arguments[1] as NamedArgument).value
                    as Literal)
                .value,
            4);
      });
    });

    test('Parses variable expression with whitespace control', () {
      testParser('{{- user -}}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        expect((variable.expression as Identifier).name, 'user');
      });
    });

    test('Parses another variable expression', () {
      testParser('{{ user.name }}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        expect(variable.name, 'user');
        final memberAccess = variable.expression as MemberAccess;
        expect((memberAccess.object as Identifier).name, 'user');
        expect(memberAccess.members, ['name']);
      });
    });

    test('Parses member expression with more depth', () {
      testParser('{{- user.name.first -}}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        expect(variable.name, 'user');
        final memberAccess = variable.expression as MemberAccess;
        expect((memberAccess.object as Identifier).name, 'user');
        expect(memberAccess.members, ['name', 'first']);
      });
    });
    test('Parses another variable expression', () {
      testParser('{{ user.name }}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        final memberAccess = variable.expression as MemberAccess;
        expect((memberAccess.object as Identifier).name, 'user');
        expect(memberAccess.members.length, 1);
        expect(memberAccess.members[0], 'name');
      });
    });

    test('Parses member expression with more depth', () {
      testParser('{{- user.name.first -}}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        expect(variable.name, 'user');
        expect(variable.expression, isA<MemberAccess>());
        final memberAccess = variable.expression as MemberAccess;
        expect(memberAccess.members.length, 2);
        expect(memberAccess.members, containsAll(const ['name', 'first']));
      });
    });

    test('Parses basic tag without content', () {
      testParser('{% tagname %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        assert(tag.content.isEmpty);
      });
    });

    test('Parses tag with variables', () {
      testParser('{% tagname my_string = "Hello World!" %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        assert(tag.content.isNotEmpty);
        expect(tag.content[0], isA<Assignment>());
      });
    });

    test('Parses tag with comma separated arguments', () {
      testParser('{% tagname var1,var2,var3, var4 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        assert(tag.content.isNotEmpty);
        expect(tag.content[0], isA<Identifier>());
        expect(tag.content[1], isA<Identifier>());
        expect(tag.content[2], isA<Identifier>());
        expect(tag.content[3], isA<Identifier>());
      });

      testParser('{% tagname "var1",var2,var3,"var4" %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        assert(tag.content.isNotEmpty);
        expect(tag.content[0], isA<Literal>());
        expect(tag.content[1], isA<Identifier>());
        expect(tag.content[2], isA<Identifier>());
        expect(tag.content[3], isA<Literal>());
      });
    });
    test('Parses tag with spac separated arguments', () {
      testParser('{% tagname var1 var2 var3 var4 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        assert(tag.content.isNotEmpty);
        expect(tag.content[0], isA<Identifier>());
        expect(tag.content[1], isA<Identifier>());
        expect(tag.content[2], isA<Identifier>());
        expect(tag.content[3], isA<Identifier>());
      });
    });

    test('Parses tag with variable and filter', () {
      testParser('{% tagname myvar | filter1 %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.content.length, 1);
        ASTNode variable = tag.content[0];
        expect((variable as Identifier).name, 'myvar');
        expect(tag.filters.length, 1);
        expect(tag.filters[0].name.name, 'filter1');
        expect(tag.filters[0].arguments.isEmpty, true);
      });
    });

    test('Parses tag with multiple filters', () {
      testParser('{% tagname | filter1 | filter2 %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.filters.length, 2);
        expect(tag.filters[0].name.name, 'filter1');
        expect(tag.filters[1].name.name, 'filter2');
      });
    });

    test('Parses tag with filter and arguments', () {
      testParser('{% tagname | filter1: arg1, arg2, "arg3" %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.filters.length, 1);
        expect(tag.filters[0].name.name, 'filter1');
        expect(tag.filters[0].arguments.length, 3);
        expect((tag.filters[0].arguments[0] as Identifier).name, 'arg1');
        expect((tag.filters[0].arguments[1] as Identifier).name, 'arg2');
        expect((tag.filters[0].arguments[2] as Literal).value, 'arg3');
      });
    });

    test('Parses tag with filter and named arguments for all literal types',
        () {
      testParser(
          '{% tagname | filter1: arg1:1, arg2:"2", arg3:\'3\', arg4:true, arg5:false %}',
          (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.filters.length, 1);
        expect(tag.filters[0].name.name, 'filter1');
        expect(tag.filters[0].arguments.length, 5);

        // Checking the first argument (number)
        expect(
            (tag.filters[0].arguments[0] as NamedArgument).name.name, 'arg1');
        expect(
            ((tag.filters[0].arguments[0] as NamedArgument).value as Literal)
                .value,
            1);
        expect(
            ((tag.filters[0].arguments[0] as NamedArgument).value as Literal)
                .type,
            LiteralType.number);

        // Checking the second argument (double-quoted string)
        expect(
            (tag.filters[0].arguments[1] as NamedArgument).name.name, 'arg2');
        expect(
            ((tag.filters[0].arguments[1] as NamedArgument).value as Literal)
                .value,
            '2');
        expect(
            ((tag.filters[0].arguments[1] as NamedArgument).value as Literal)
                .type,
            LiteralType.string);

        // Checking the third argument (single-quoted string)
        expect(
            (tag.filters[0].arguments[2] as NamedArgument).name.name, 'arg3');
        expect(
            ((tag.filters[0].arguments[2] as NamedArgument).value as Literal)
                .value,
            '3');
        expect(
            ((tag.filters[0].arguments[2] as NamedArgument).value as Literal)
                .type,
            LiteralType.string);

        // Checking the fourth argument (boolean true)
        expect(
            (tag.filters[0].arguments[3] as NamedArgument).name.name, 'arg4');
        expect(
            ((tag.filters[0].arguments[3] as NamedArgument).value as Literal)
                .value,
            true);
        expect(
            ((tag.filters[0].arguments[3] as NamedArgument).value as Literal)
                .type,
            LiteralType.boolean);

        // Checking the fifth argument (boolean false)
        expect(
            (tag.filters[0].arguments[4] as NamedArgument).name.name, 'arg5');
        expect(
            ((tag.filters[0].arguments[4] as NamedArgument).value as Literal)
                .value,
            false);
        expect(
            ((tag.filters[0].arguments[4] as NamedArgument).value as Literal)
                .type,
            LiteralType.boolean);
      });
    });

    test('Parses tag with arguments and filters', () {
      testParser('{% tagname arg1 "arg2" | filter1 | filter2: 123 %}',
          (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.content.length, 2);
        expect((tag.content[0] as Identifier).name, 'arg1');
        expect((tag.content[1] as Literal).value, 'arg2');
        expect(tag.filters.length, 2);
        expect(tag.filters[0].name.name, 'filter1');
        expect(tag.filters[1].name.name, 'filter2');
        expect(tag.filters[1].arguments.length, 1);
        expect((tag.filters[1].arguments[0] as Literal).value, 123);
      });
    });

    test('Parses assignments within tags', () {
      testParser('{% if user %}{% assign my_variable = "string" %}{% endif %}',
          (document) {
        expect(document.children.length, 1);

        final ifTag = document.children[0] as Tag;
        expect(ifTag.name, 'if');
        expect(ifTag.body.length, 1);

        expect((ifTag.content[0] as Identifier).name, 'user');

        final assignTag = ifTag.body[0] as Tag;
        expect(assignTag.name, 'assign');
        expect(
            ((assignTag.content[0] as Assignment).variable as Identifier).name,
            'my_variable');
        expect((assignTag.content[0] as Assignment).value is Literal, true);
        expect(((assignTag.content[0] as Assignment).value as Literal).value,
            'string');
      });
    });

    test('Parses comparison operators', () {
      final comparisonTests = [
        '{% if 1 == 1 %}Equal{% endif %}',
        '{% if 1 != 2 %}Not Equal{% endif %}',
        '{% if 1 < 2 %}Less than{% endif %}',
        '{% if 2 > 1 %}Greater than{% endif %}',
        '{% if 1 <= 1 %}Less than or equal{% endif %}',
        '{% if 2 >= 1 %}Greater than or equal{% endif %}',
      ];

      for (final testCase in comparisonTests) {
        testParser(testCase, (document) {
          expect(document.children.length, 1);
          final ifTag = document.children[0] as Tag;
          expect(ifTag.name, 'if');
          expect(ifTag.content[0] is BinaryOperation, true);
          expect(ifTag.body.length, 1);
        });
      }
    });

    test('Parses unary operations', () {
      testParser('{% if not user.is_logged_in %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content[0], isA<UnaryOperation>());
      });

      testParser('{% if !user.is_logged_in %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content[0], isA<UnaryOperation>());
      });
    });

    test('Parses simple logical AND operation', () {
      testParser('{% if true and false %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final operation = tag.content[0] as BinaryOperation;
        expect(operation.operator, 'and');
        expect((operation.left as Literal).value, true);
        expect((operation.right as Literal).value, false);
      });
    });

    test('Parses logical OR operation', () {
      testParser('{% if true or false %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final operation = tag.content[0] as BinaryOperation;
        expect(operation.operator, 'or');
        expect((operation.left as Literal).value, true);
        expect((operation.right as Literal).value, false);
      });
    });

    test('Parses mixed logical AND/OR operation', () {
      testParser('{% if true and false or true %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');

        // The root operation should be 'or'
        final rootOperation = tag.content[0] as BinaryOperation;
        expect(rootOperation.operator, 'or');

        // The left-hand side of 'or' should be an 'and' operation
        final leftOperation = rootOperation.left as BinaryOperation;
        expect(leftOperation.operator, 'and');
        expect((leftOperation.left as Literal).value, true);
        expect((leftOperation.right as Literal).value, false);

        // The right-hand side of 'or' should be a Literal true
        expect((rootOperation.right as Literal).value, true);
      });
    });

    test('Parses logical operation with comparison', () {
      testParser('{% if 1 == 1 and 2 > 1 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final operation = tag.content[0] as BinaryOperation;

        // Expect AND operation as the root
        expect(operation.operator, 'and');

        // The left side should be a comparison
        final leftComparison = operation.left as BinaryOperation;
        expect(leftComparison.operator, '==');
        expect((leftComparison.left as Literal).value, 1);
        expect((leftComparison.right as Literal).value, 1);

        // The right side should be a comparison
        final rightComparison = operation.right as BinaryOperation;
        expect(rightComparison.operator, '>');
        expect((rightComparison.left as Literal).value, 2);
        expect((rightComparison.right as Literal).value, 1);
      });
    });

    test('Parses logical operation with unary NOT', () {
      testParser('{% if not false %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final operation = tag.content[0] as UnaryOperation;
        expect(operation.operator, 'not');
        expect((operation.expression as Literal).value, false);
      });
    });

    test('Parses complex logical operation with unary and binary operators',
        () {
      testParser('{% if not false and 1 == 1 or 2 < 3 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final operation = tag.content[0] as BinaryOperation;

        // Expect OR operation as the root
        expect(operation.operator, 'or');

        // The left side should be an AND operation
        final leftOperation = operation.left as BinaryOperation;
        expect(leftOperation.operator, 'and');

        // The left side of the AND should be a NOT operation
        final notOperation = leftOperation.left as UnaryOperation;
        expect(notOperation.operator, 'not');
        expect((notOperation.expression as Literal).value, false);

        // The right side of the AND should be a comparison
        final comparison = leftOperation.right as BinaryOperation;
        expect(comparison.operator, '==');
        expect((comparison.left as Literal).value, 1);
        expect((comparison.right as Literal).value, 1);

        // The right side of the OR should be a comparison
        final rightComparison = operation.right as BinaryOperation;
        expect(rightComparison.operator, '<');
        expect((rightComparison.left as Literal).value, 2);
        expect((rightComparison.right as Literal).value, 3);
      });
    });

    test('Parses contains operator', () {
      final containsTests = [
        '{% if product.title contains "Pack" %}Contains Pack{% endif %}',
        '{% if product.tags contains "Hello" %}Contains Hello{% endif %}',
      ];

      for (final testCase in containsTests) {
        testParser(testCase, (document) {
          expect(document.children.length, 1);
          final ifTag = document.children[0] as Tag;
          expect(ifTag.name, 'if');
          expect(ifTag.content[0] is BinaryOperation, true);
          expect(ifTag.body.length, 1);
        });
      }
    });

    test('Parses a simple range in a tag', () {
      testParser('{% for i in (1..5) %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'for');
        expect(tag.content.length, 1);

        final inOperator = tag.content[0] as BinaryOperation;
        expect(inOperator.operator, 'in');

        expect((inOperator.left), isA<Identifier>());
        expect((inOperator.right), isA<BinaryOperation>());

        expect((inOperator.left as Identifier).name, 'i');

        final range = inOperator.right as BinaryOperation;
        expect(range.operator, '..');
        expect((range.left as Literal).value, 1);
        expect((range.right as Literal).value, 5);
      });
    });

    test('Parses a range in an if statement', () {
      testParser('{% if (3..7) contains 5 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final containsOperation = tag.content[0] as BinaryOperation;
        expect(containsOperation.operator, 'contains');

        final range = containsOperation.left as BinaryOperation;
        expect(range.operator, '..');
        expect((range.left as Literal).value, 3);
        expect((range.right as Literal).value, 7);

        expect((containsOperation.right as Literal).value, 5);
      });
    });

    test('Parses a complex range with logical operators', () {
      testParser('{% if i in (1..5) and j in (6..10) %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final andOperation = tag.content[0] as BinaryOperation;
        expect(andOperation.operator, 'and');

        final firstInOperation = andOperation.left as BinaryOperation;
        expect(firstInOperation.operator, 'in');

        final secondInOperation = andOperation.right as BinaryOperation;
        expect(secondInOperation.operator, 'in');

        // First in operation check
        expect((firstInOperation.left as Identifier).name, 'i');
        final firstRange = firstInOperation.right as BinaryOperation;
        expect(firstRange.operator, '..');
        expect((firstRange.left as Literal).value, 1);
        expect((firstRange.right as Literal).value, 5);

        // Second in operation check
        expect((secondInOperation.left as Identifier).name, 'j');
        final secondRange = secondInOperation.right as BinaryOperation;
        expect(secondRange.operator, '..');
        expect((secondRange.left as Literal).value, 6);
        expect((secondRange.right as Literal).value, 10);
      });
    });

    test('Parses a simple grouped expression', () {
      testParser('{% if (1 + 2) == 3 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final comparison = tag.content[0] as BinaryOperation;
        expect(comparison.operator, '==');

        final groupedExpression = (comparison.left as GroupedExpression)
            .expression as BinaryOperation;
        expect(groupedExpression.operator, '+');
        expect((groupedExpression.left as Literal).value, 1);
        expect((groupedExpression.right as Literal).value, 2);

        expect((comparison.right as Literal).value, 3);
      });
    });

    test('Parses nested grouped expressions', () {
      testParser('{% if ((1 + 2) * 3) == 9 %}', (document) {
        expect(document.children.length, 1);

        final tag = document.children[0] as Tag;
        expect(tag.name, 'if');
        expect(tag.content.length, 1);

        final comparison = tag.content[0] as BinaryOperation;
        expect(comparison.operator, '==');

        final outerGroup = (comparison.left as GroupedExpression);
        final groupedExpression = outerGroup.expression as BinaryOperation;
        expect(groupedExpression.operator, '*');

        final innerGroup = groupedExpression.left as GroupedExpression;
        final innerExpression = innerGroup.expression as BinaryOperation;
        expect(innerExpression.operator, '+');
        expect((innerExpression.left as Literal).value, 1);
        expect((innerExpression.right as Literal).value, 2);

        expect((groupedExpression.right as Literal).value, 3);
        expect((comparison.right as Literal).value, 9);
      });
    });

    group('control flow', () {
      group('IfTag', () {
        test('basic if statement', () {
          testParser(
              '{% if true %}'
              'Should be True'
              '{% mytag %}'
              '{% endif %}', (document) {
            expect(document.children.length, 1);
            final ifTag = document.children[0] as Tag;
            expect(ifTag.name, 'if');
            expect(ifTag.content.length, 1);

            expect((ifTag.content[0] as Literal).value, true);

            expect(ifTag.body.length, 2);
            expect(ifTag.body[0], isA<TextNode>());
            expect(ifTag.body[1], isA<Tag>());
          });
        });

        test('if-else statement', () {
          testParser(
              '{% if false %}'
                  'True'
              '{% else %}'
                  'False'
              '{% endif %}', (document) {
            expect(document.children.length, 1);
            final ifTag = document.children[0] as Tag;
            expect(ifTag.name, 'if');
            expect(ifTag.content.length, 1);
            expect((ifTag.content[0] as Literal).value, false);

            expect(ifTag.body.length, 2);
            expect(ifTag.body[0], isA<TextNode>());
            expect(ifTag.body[1], isA<Tag>());
            // expect(ifTag.elseBody.length, 1);
            // expect(ifTag.elseBody[0], isA<TextNode>());
          });
        });

        test('nested if statements', () {
          testParser(
              '{% if true %}'
                  '{% if false %}'
                      'Inner False'
                  '{% else %}'
                      'Inner True'
                  '{% endif %}'
              '{% endif %}', (document) {
            expect(document.children.length, 1);
            final outerIfTag = document.children[0] as Tag;
            expect(outerIfTag.name, 'if');
            expect(outerIfTag.content.length, 1);
            expect((outerIfTag.content[0] as Literal).value, true);
            expect(outerIfTag.body.length, 1);

            final innerIfTag = outerIfTag.body[0] as Tag;
            expect(innerIfTag.name, 'if');
            expect(innerIfTag.content.length, 1);
            expect((innerIfTag.content[0] as Literal).value, false);
            expect(innerIfTag.body.length, 2);
            expect(innerIfTag.body[0], isA<TextNode>());
            expect(innerIfTag.body[1], isA<Tag>());
          });
        });

        test('if statement with break', () {
          testParser(
              '{% for item in (1..5) %}'
                '{% if item == 3 %}'
                    '{% break %}'
                '{% endif %}'
                '{{ item }}'
              '{% endfor %}', (document) {
            expect(document.children.length, 1);
            final forTag = document.children[0] as Tag;
            expect(forTag.name, 'for');
            expect(forTag.body.length, 2);

            final ifTag = forTag.body[0] as Tag;
            expect(ifTag.name, 'if');
            expect(ifTag.content.length, 1);
            expect(ifTag.content[0], isA<BinaryOperation>());
            expect(ifTag.body.length, 1);
            expect((ifTag.body[0] as Tag).name, 'break');

            expect(forTag.body[1], isA<Variable>());
          });
        });

        test('if statement with continue', () {
          testParser(
              '{% for item in (1..5) %}'
                  '{% if item == 3 %}'
                      '{% continue %}'
                  '{% endif %}'
                  '{{ item }}'
              '{% endfor %}', (document) {
            expect(document.children.length, 1);
            final forTag = document.children[0] as Tag;
            expect(forTag.name, 'for');
            expect(forTag.body.length, 2);

            final ifTag = forTag.body[0] as Tag;
            expect(ifTag.name, 'if');
            expect(ifTag.content.length, 1);
            expect(ifTag.content[0], isA<BinaryOperation>());
            expect(ifTag.body.length, 1);
            expect((ifTag.body[0] as Tag).name, 'continue');

            expect(forTag.body[1], isA<Variable>());
          });
        });
      });
    });
  });
}

Result parse(String input, [bool enableTrace = false]) {
  final parser = LiquidGrammar().build();
  if (enableTrace) {
    return trace(parser).parse(input);
  } else {
    return parser.parse(input);
  }
}

void testParser(String source, void Function(Document document) testFunction) {
  try {
    final result = parse(source);
    if (result is Success) {
      final document = result.value as Document;
      try {
        testFunction(document);
      } catch (e) {
        print('Error: $e');
        printAST(document, 0);

        JsonEncoder encoder = JsonEncoder.withIndent('  ');
        final encoded = encoder.convert(document);
        print(encoded);

        rethrow;
      }
    } else {
      fail('Parsing failed: ${result.message}\nSource: $source');
    }
  } catch (e, trace) {
    print("source: $source");
    print('Error: $e');
    print('Trace: $trace');
    rethrow;
  }
}
