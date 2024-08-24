import 'package:liquify/src/ast.dart';

void printAST(ASTNode node, int indent) {
  final indentStr = '   ' * indent;
  print('$indentStr${node.runtimeType}');

  if (node is Document) {
    for (final child in node.children) {
      printAST(child, indent + 1);
    }
  } else if (node is Tag) {
    print('$indentStr  Name: ${node.name}');
    print('$indentStr  Content:');
    for (final child in node.content) {
      printAST(child, indent + 2);
    }
    if (node.filters.isNotEmpty) {
      print('$indentStr  Filters:');
      for (final filter in node.filters) {
        printAST(filter, indent + 2);
      }
    }
  } else if (node is Assignment) {
    print('$indentStr  Variable: ${node.variable}');
    print('$indentStr  Value:');
    printAST(node.value, indent + 2);
  } else if (node is BinaryOperation) {
    print('$indentStr  Operator: ${node.operator}');
    print('$indentStr  Left:');
    printAST(node.left, indent + 2);
    print('$indentStr  Right:');
    printAST(node.right, indent + 2);
  } else if (node is UnaryOperation) {
    print('$indentStr  Operator: ${node.operator}');
    print('$indentStr  Expression:');
    printAST(node.expression, indent + 4);
  } else if (node is FilteredExpression) {
    print('$indentStr  Filters: ');
    print('$indentStr  Expression:');
    printAST(node.expression, indent + 2);
    print('$indentStr  Arguments:');
    for (final arg in node.filters) {
      printAST(arg, indent + 2);
    }
  } else if (node is MemberAccess) {
    print('$indentStr  Member: ${node.members.join('.')}');
    print('$indentStr  Object:');
    printAST(node.object, indent + 2);
  } else if (node is Literal) {
    print('$indentStr  Value: ${node.value} (Type: ${node.type})');
  } else if (node is Identifier) {
    print('$indentStr  Name: ${node.name}');
  } else if (node is TextNode) {
    print('$indentStr  Text: ${node.text}');
  } else if (node is NamedArgument) {
    print('$indentStr  Named Argument: ${node.identifier.name}');
    print('$indentStr  Value:');
    printAST(node.value, indent + 2);
  } else if (node is Filter) {
    print('$indentStr  Filter Name: ${node.name.name}');
    print('$indentStr  Arguments:');
    for (final arg in node.arguments) {
      printAST(arg, indent + 2);
    }
  } else if (node is Variable) {
    print('$indentStr  Variable Name: ${node.name}');
    print('$indentStr  Expression:');
    printAST(node.expression, indent + 2);
  }
}

(List<ASTNode>, int) findTagChildren(List<ASTNode> nodes, Tag startTag) {
  final endTagName = 'end${startTag.name}';
  var nestedCount = 0;
  final startIndex = nodes.indexOf(startTag);
  final children = <ASTNode>[];

  for (int i = startIndex + 1; i < nodes.length; i++) {
    final child = nodes[i];
    if (child is Tag) {
      if (child.name == startTag.name) {
        nestedCount++;
        children.add(child);
      } else if (child.name == endTagName) {
        if (nestedCount == 0) {
          // We found the matching end tag
          startTag.body = children;
          return (children, i);
        } else {
          nestedCount--;
          children.add(child);
        }
      } else {
        children.add(child);
      }
    } else {
      children.add(child);
    }
  }

  throw Exception('Missing end tag: $endTagName');
}
