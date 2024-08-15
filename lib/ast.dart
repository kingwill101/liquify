class ASTNode {}

class Document extends ASTNode {
  final List<ASTNode> children;

  Document(this.children);
}

class Variable extends ASTNode {
  final String name;
  final Expression expression;

  Variable(this.name, this.expression);
}

class Tag extends ASTNode {
  final String name;
  final List<ASTNode> content;

  Tag(this.name, this.content);
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

  BinaryOperation(this.operator, this.left, this.right);
}

class Expression extends ASTNode {}

class Identifier extends Expression {
  final String name;

  Identifier(this.name);
}

class Literal extends Expression {
  final String value;

  Literal(this.value);
}

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
