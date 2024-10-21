import 'package:liquify/src/ast.dart';

/// Prints the abstract syntax tree (AST) representation of the given [node] with the specified [indent] level.
///
/// This function recursively prints the structure of the AST, displaying the type of each node and its
/// relevant properties, such as the name of a tag, the variable and value of an assignment, the
/// operator and operands of a binary or unary operation, and so on.
///
/// The [indent] parameter controls the indentation level of the printed output, with each level
/// represented by three spaces.
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

/// Determines whether the given data is considered "truthy" or not.
///
/// This function checks the value of the [data] parameter and returns `true` if it
/// is considered truthy, and `false` otherwise. The rules for determining
/// truthiness are:
///
/// - If [data] is not `null` and not `false`, it is considered truthy.
/// - If [data] is a [Literal] and its [type] is not [LiteralType.nil], it is considered truthy.
/// - If [data] is a [Literal], its [type] is not [LiteralType.boolean], and its [value] is not `false`, it is considered truthy.
bool isTruthy(dynamic data) {
  return (data != null && data != false) ||
      ((data is Literal) && data.type != LiteralType.nil) ||
      ((data is Literal) &&
          data.type != LiteralType.boolean &&
          data.value != false);
}
