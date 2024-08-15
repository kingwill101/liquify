import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/grammar.dart';
import 'package:test/test.dart';
import 'package:petitparser/petitparser.dart';

void main() {
  group('Liquid Grammar Parser', () {
    test('Parses simple variable expression', () {
      testParser('{{ user }}', (document) {
        expect(document.children.length, 1);

        final variable = document.children[0] as Variable;
        expect((variable.expression as Identifier).name, 'user');
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

      test('Parses general tag', () {
        testParser('{% tagname %}', (document) {
          expect(document.children.length, 1);

          final tag = document.children[0] as Tag;
          expect(tag.name, 'tagname');
        });
      });

    //   test('Parses assignments within tags', () {
    //     testParser('{% if user %}{% assign my_variable = "string" %}{% endif %}',
    //         (document) {
    //       expect(document.children.length, 3);

    //       final ifTag = document.children[0] as Tag;
    //       expect(ifTag.name, 'if');
    //       expect((ifTag.content[0] as Identifier).name, 'user');

    //       final assignTag = document.children[1] as Tag;
    //       expect(assignTag.name, 'assign');
    //       expect((assignTag.content[0] as Assignment).variable, 'my_variable');
    //       expect((assignTag.content[0] as Assignment).value is Literal, true);
    //       expect(((assignTag.content[0] as Assignment).value as Literal).value,
    //           'string');
    //     });
    //   });

    //   test('Parses comparison operators', () {
    //     final comparisonTests = [
    //       '{% if 1 == 1 %}Equal{% endif %}',
    //       '{% if 1 != 2 %}Not Equal{% endif %}',
    //       '{% if 1 < 2 %}Less than{% endif %}',
    //       '{% if 2 > 1 %}Greater than{% endif %}',
    //       '{% if 1 <= 1 %}Less than or equal{% endif %}',
    //       '{% if 2 >= 1 %}Greater than or equal{% endif %}',
    //     ];

    //     for (final testCase in comparisonTests) {
    //       testParser(testCase, (document) {
    //         expect(document.children.length, 3);
    //         final ifTag = document.children[0] as Tag;
    //         expect(ifTag.name, 'if');
    //         expect(ifTag.content[0] is BinaryOperation, true);
    //       });
    //     }
    //   });

    //   test('Parses logical operators', () {
    //     final logicalTests = [
    //       '{% if product.type == "Shirt" or product.type == "Shoes" %}This is a shirt or a pair of shoes.{% endif %}',
    //       '{% if true or false and false %}True{% endif %}',
    //       '{% if true and false and false or true %}False{% endif %}',
    //     ];

    //     for (final testCase in logicalTests) {
    //       testParser(testCase, (document) {
    //         expect(document.children.length, 3);
    //         final ifTag = document.children[0] as Tag;
    //         expect(ifTag.name, 'if');
    //         expect(ifTag.content[0] is BinaryOperation, true);
    //       });
    //     }
    //   });

    //   test('Parses contains operator', () {
    //     final containsTests = [
    //       '{% if product.title contains "Pack" %}Contains Pack{% endif %}',
    //       '{% if product.tags contains "Hello" %}Contains Hello{% endif %}',
    //     ];

    //     for (final testCase in containsTests) {
    //       testParser(testCase, (document) {
    //         expect(document.children.length, 3);
    //         final ifTag = document.children[0] as Tag;
    //         expect(ifTag.name, 'if');
    //         expect(ifTag.content[0] is BinaryOperation, true);
    //       });
    //     }
    //   });
  });
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
        rethrow;
      }
    } else {
      fail('Parsing failed: ${result.message}\nSource: $source');
    }
  } catch (e) {
    print("source: $source");
    print('Error: $e');
    rethrow;
  }
}

void printAST(ASTNode node, int indent) {
  final indentStr = ' ' * indent;
  print('${indentStr}${node.runtimeType}');
  if (node is Document) {
    for (final child in node.children) {
      printAST(child, indent + 1);
    }
  } else if (node is Variable) {
    printAST(node.expression, indent + 1);
  } else if (node is BinaryOperation) {
    print('${indentStr}  Operator: ${node.operator}');
    print('${indentStr}  Left:');
    printAST(node.left, indent + 2);
    print('${indentStr}  Right:');
    printAST(node.right, indent + 2);
  } else if (node is UnaryOperation) {
    print('${indentStr}  Operator: ${node.operator}');
    printAST(node.expression, indent + 1);
  } else if (node is FilterExpression) {
    print('${indentStr}  Filter: ${node.filter}');
    print('${indentStr}  Expression:');
    printAST(node.expression, indent + 2);
    print('${indentStr}  Arguments:');
    for (final arg in node.arguments) {
      printAST(arg, indent + 2);
    }
  } else if (node is MemberAccess) {
    print('${indentStr}  Member: ${node.members.join('.')}');
    print('${indentStr}  Object:');
    printAST(node.object, indent + 2);
  } else if (node is Literal) {
    print('${indentStr}  Value: ${node.value}');
  } else if (node is Identifier) {
    print('${indentStr}  Name: ${node.name}');
  } else if (node is TextNode) {
    print('${indentStr}  Text: ${node.text}');
  }
}
