import 'package:liquid_grammar/visitor.dart';
import 'package:uuid/uuid.dart';

abstract class ASTNode {
  final String id;

  ASTNode() : id = Uuid().v4();

  Map<String, dynamic> toJson() => {};

  T accept<T>(ASTVisitor<T> visitor);
}

class Document extends ASTNode {
  final List<ASTNode> children;

  Document(this.children);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Document',
        'children': children.map((child) => child.toJson()).toList(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitDocument(this);
}

class Tag extends ASTNode {
  final String name;
  final List<ASTNode> content;
  List<ASTNode> body;
  final List<Filter> filters;

  Tag(
    this.name,
    this.content, {
    this.filters = const [],
    this.body = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Tag',
        'name': name,
        'content': content.map((child) => child.toJson()).toList(),
        'body': body.map((child) => child.toJson()).toList(),
        'filters': filters.map((filter) => filter.toJson()).toList(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitTag(this);
}

class GroupedExpression extends ASTNode {
  final ASTNode expression;

  GroupedExpression(this.expression);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'GroupedExpression',
        'expression': expression.toJson(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitGroupedExpression(this);
}

class Assignment extends ASTNode {
  final ASTNode variable;
  final ASTNode value;

  Assignment(this.variable, this.value);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Assignment',
        'variable': variable,
        'value': value.toJson(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitAssignment(this);
}

class BinaryOperation extends ASTNode {
  final String operator;
  final ASTNode left;
  final ASTNode right;

  BinaryOperation(this.left, this.operator, this.right);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'BinaryOperation',
        'operator': operator,
        'left': left.toJson(),
        'right': right.toJson(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitBinaryOperation(this);
}

class Identifier extends ASTNode {
  final String name;

  Identifier(this.name);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Identifier',
        'name': name,
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitIdentifier(this);
}

class Literal extends ASTNode {
  final dynamic _value;
  final LiteralType type;

  Literal(this._value, this.type);

  get value => switch (type) {
        LiteralType.string => _value.toString(),
        LiteralType.number => _value is num || _value is int || _value is double
            ? _value
            : num.parse(_value as String),
        LiteralType.boolean => _value is bool
            ? _value
            : _value == 'true'
                ? true
                : false,
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitLiteral(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Literal',
        'value': value,
        'literalType': type.toString().split('.').last,
      };
}

enum LiteralType { string, number, boolean }

class TextNode extends ASTNode {
  final String text;

  TextNode(this.text);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitTextNode(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TextNode',
        'text': text,
      };
}

class MemberAccess extends ASTNode {
  final ASTNode object;
  final List<String> members;

  MemberAccess(this.object, this.members);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'MemberAccess',
        'object': object.toJson(),
        'members': members,
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitMemberAccess(this);
}

class UnaryOperation extends ASTNode {
  final String operator;
  final ASTNode expression;

  UnaryOperation(this.operator, this.expression);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitUnaryOperation(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'UnaryOperation',
        'operator': operator,
        'expression': expression.toJson(),
      };
}

class Variable extends ASTNode {
  final ASTNode expression;
  final String name;

  Variable(this.name, this.expression);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Variable',
        'name': name,
        'expression': expression.toJson(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitVariable(this);
}

class FilteredExpression extends ASTNode {
  final ASTNode expression;
  final List<Filter> filters;

  FilteredExpression(this.expression, this.filters);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'FilteredExpression',
        'expression': expression.toJson(),
        'filters': filters.map((filter) => filter.toJson()).toList(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitFilterExpression(this);
}

class Filter extends ASTNode {
  final Identifier name;
  final List<ASTNode> arguments;

  Filter(this.name, this.arguments);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Filter',
        'name': name.toJson(),
        'arguments': arguments.map((arg) => arg.toJson()).toList(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitFilter(this);
}

class NamedArgument extends ASTNode {
  final Identifier name;
  final ASTNode value;

  NamedArgument(this.name, this.value);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitNamedArgument(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'NamedArgument',
        'name': name.toJson(),
        'value': value.toJson(),
      };
}
