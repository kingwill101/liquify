class ASTNode {
  Map<String, dynamic> toJson() => {};
}

class Document extends ASTNode {
  final List<ASTNode> children;

  Document(this.children);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Document',
        'children': children.map((child) => child.toJson()).toList(),
      };
}

class Tag extends ASTNode {
  final String name;
  final List<ASTNode> content;
  final List<Filter> filters;

  Tag(this.name, this.content, {this.filters = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Tag',
        'name': name,
        'content': content.map((child) => child.toJson()).toList(),
        'filters': filters.map((filter) => filter.toJson()).toList(),
      };
}

class Assignment extends ASTNode {
  final String variable;
  final Expression value;

  Assignment(this.variable, this.value);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Assignment',
        'variable': variable,
        'value': value.toJson(),
      };
}

class BinaryOperation extends Expression {
  final String operator;
  final Expression left;
  final Expression right;

  BinaryOperation(this.left, this.operator, this.right);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'BinaryOperation',
        'operator': operator,
        'left': left.toJson(),
        'right': right.toJson(),
      };
}

class Expression extends ASTNode {}

class Identifier extends Expression {
  final String name;

  Identifier(this.name);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Identifier',
        'name': name,
      };
}

class Literal extends Expression {
  final dynamic value;
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
  Map<String, dynamic> toJson() => {
        'type': 'TextNode',
        'text': text,
      };
}

class MemberAccess extends Expression {
  final Expression object;
  final List<String> members;

  MemberAccess(this.object, this.members);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'MemberAccess',
        'object': object.toJson(),
        'members': members,
      };
}

class UnaryOperation extends Expression {
  final String operator;
  final Expression expression;

  UnaryOperation(this.operator, this.expression);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'UnaryOperation',
        'operator': operator,
        'expression': expression.toJson(),
      };
}

class FilterExpression extends Expression {
  final String filter;
  final Expression expression;
  final List<Expression> arguments;

  FilterExpression(this.filter, this.expression, this.arguments);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'FilterExpression',
        'filter': filter,
        'expression': expression.toJson(),
        'arguments': arguments.map((arg) => arg.toJson()).toList(),
      };
}

class Variable extends ASTNode {
  final Expression expression;
  final String name;

  Variable(this.name, this.expression);

  List<Filter> get filters => expression is FilteredExpression
      ? (expression as FilteredExpression).filters
      : [];

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Variable',
        'name': name,
        'expression': expression.toJson(),
        'filters': filters.map((filter) => filter.toJson()).toList(),
      };
}

class FilteredExpression extends ASTNode {
  final Expression expression;
  final List<Filter> filters;

  FilteredExpression(this.expression, this.filters);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'FilteredExpression',
        'expression': expression.toJson(),
        'filters': filters.map((filter) => filter.toJson()).toList(),
      };
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
}

class NamedArgument extends ASTNode {
  final Identifier name;
  final Expression value;

  NamedArgument(this.name, this.value);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'NamedArgument',
        'name': name.toJson(),
        'value': value.toJson(),
      };
}
