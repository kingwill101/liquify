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

    test('Parses tag with variable and filter', () {
      testParser('{% tagname myvar | filter1 %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.content.length, 1);
        final variable = tag.content[0] as Identifier;
        expect(variable.name, 'myvar');
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
      testParser('{% tagname | filter1: arg1, "arg2" %}', (document) {
        expect(document.children.length, 1);
        final tag = document.children[0] as Tag;
        expect(tag.name, 'tagname');
        expect(tag.filters.length, 1);
        expect(tag.filters[0].name.name, 'filter1');
        expect(tag.filters[0].arguments.length, 2);
        expect((tag.filters[0].arguments[0] as Identifier).name, 'arg1');
        expect((tag.filters[0].arguments[1] as Literal).value, 'arg2');
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
        expect((tag.filters[1].arguments[0] as Literal).value, '123');
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

Result parse(String input) {
  final parser = LiquidGrammar().build();
  return parser.parse(input);
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
