import 'package:liquid_grammar/ast.dart';

void printAST(ASTNode node, int indent) {
  final indentStr = ' ' * indent;
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
    print('$indentStr  Filters:');
    for (final filter in node.filters) {
      printAST(filter, indent + 2);
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
  } else if (node is FilterExpression) {
    print('$indentStr  Filter: ${node.filter}');
    print('$indentStr  Expression:');
    printAST(node.expression, indent + 2);
    print('$indentStr  Arguments:');
    for (final arg in node.arguments) {
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
    print('$indentStr  Named Argument: ${node.name.name}');
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
