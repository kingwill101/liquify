class ASTNode {}

class Document extends ASTNode {
  final List<ASTNode> children;

  Document(this.children);
}

class Tag extends ASTNode {
  final String name;
  final List<ASTNode> content;
  final List<Filter> filters;

  Tag(this.name, this.content, {this.filters = const []});
}

class Assignment extends ASTNode {
  final String variable;
  final Expression value;

  Assignment(this.variable, this.value);
}

class BinaryOperation extends Expression {
  final String operator;
  final Expression left;
  final Expression right;

  BinaryOperation(this.left, this.operator,this.right);
}

class Expression extends ASTNode {}

class Identifier extends Expression {
  final String name;

  Identifier(this.name);
}

class Literal extends Expression {
  final dynamic value;
  final LiteralType type;

  Literal(this.value, this.type);
}

enum LiteralType { string, number, boolean }

class TextNode extends ASTNode {
  final String text;

  TextNode(this.text);
}

class MemberAccess extends Expression {
  final Expression object;
  final List<String> members;

  MemberAccess(this.object, this.members);
}

class UnaryOperation extends Expression {
  final String operator;
  final Expression expression;

  UnaryOperation(this.operator, this.expression);
}

class FilterExpression extends Expression {
  final String filter;
  final Expression expression;
  final List<Expression> arguments;

  FilterExpression(this.filter, this.expression, this.arguments);
}

class Variable extends ASTNode {
  final Expression expression;
  final String name;

  Variable(this.name, this.expression);

  List<Filter> get filters => expression is FilteredExpression
      ? (expression as FilteredExpression).filters
      : [];
}

class FilteredExpression extends ASTNode {
  final Expression expression;
  final List<Filter> filters;

  FilteredExpression(this.expression, this.filters);
}

class Filter extends ASTNode {
  final Identifier name;
  final List<ASTNode> arguments;

  Filter(this.name, this.arguments);
}

class NamedArgument extends ASTNode {
  final Identifier name;
  final Expression value;

  NamedArgument(this.name, this.value);
}
