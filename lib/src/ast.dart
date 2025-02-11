import 'package:liquify/parser.dart';
import 'package:liquify/src/visitor.dart';

abstract class ASTNode {
  ASTNode();

  Map<String, dynamic> toJson() => {};

  T accept<T>(ASTVisitor<T> visitor);
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor);
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitDocumentAsync(this);
}

class Tag extends ASTNode {
  final String name;
  final List<ASTNode> _content;
  final List<ASTNode> _body;
  final List<Filter> filters;

  Tag(
    this.name,
    List<ASTNode>? content, {
    this.filters = const [],
    List<ASTNode>? body,
  })  : _body = body ?? [],
        _content = content ?? [];

  List<ASTNode> get body => collapseTextNodes(_body);

  List<ASTNode> get content => collapseTextNodes(_content);

  set body(List<ASTNode> value) {
    _body.clear();
    _body.addAll(collapseTextNodes(value));
  }

  set content(List<ASTNode> value) {
    _content.clear();
    _content.addAll(collapseTextNodes(value));
  }

  Tag copyWith({
    String? name,
    List<ASTNode>? content,
    List<Filter>? filters,
    List<ASTNode>? body,
  }) {
    return Tag(
      name ?? this.name,
      content ?? this.content,
      filters: filters ?? this.filters,
      body: body ?? this.body,
    );
  }

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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitTagAsync(this);

  @override
  String toString() {
    return 'Tag(name: $name, content: $content, body: $body, filters: $filters)';
  }
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitGroupedExpressionAsync(this);
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitAssignmentAsync(this);
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitBinaryOperationAsync(this);
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitIdentifierAsync(this);

  @override
  bool operator ==(Object other) {
    if (other is Identifier) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll(['name']);
}

class Empty {
  @override
  bool operator ==(Object other) {
    if (other is String) {
      return other.isEmpty;
    } else if (other is List) {
      return other.isEmpty;
    } else if (other is Empty) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => 0;
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
        LiteralType.array => _value as List,
        LiteralType.nil => null,
        LiteralType.empty => Empty(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitLiteral(this);

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitLiteralAsync(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Literal',
        'value': value,
        'literalType': type.toString().split('.').last,
      };

  @override
  bool operator ==(Object other) {
    if (other is Literal) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([value]);
}

enum LiteralType { string, number, boolean, array, nil, empty }

class TextNode extends ASTNode {
  final String text;

  TextNode(this.text);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitTextNode(this);

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitTextNodeAsync(this);
  @override
  String toString() {
    return text;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TextNode',
        'text': text,
      };
}

class MemberAccess extends ASTNode {
  final ASTNode object;
  final List<ASTNode> members;

  MemberAccess(this.object, this.members);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'MemberAccess',
        'object': object.toJson(),
        'members': members,
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitMemberAccess(this);

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitMemberAccessAsync(this);
}

class ArrayAccess extends ASTNode {
  final ASTNode array;
  final ASTNode key;

  ArrayAccess(this.array, this.key);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ArrayAccess',
        'array': array.toJson(),
        'key': key.toJson(),
      };

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitArrayAccess(this);

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitArrayAccessAsync(this);
}

class UnaryOperation extends ASTNode {
  final String operator;
  final ASTNode expression;

  UnaryOperation(this.operator, this.expression);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitUnaryOperation(this);

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitUnaryOperationAsync(this);

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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitVariableAsync(this);
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitFilterExpressionAsync(this);
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

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitFilterAsync(this);
}

class NamedArgument extends ASTNode {
  final Identifier identifier;
  final ASTNode value;

  NamedArgument(this.identifier, this.value);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitNamedArgument(this);

  @override
  Future<T> acceptAsync<T>(ASTVisitor<T> visitor) =>
      visitor.visitNamedArgumentAsync(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'NamedArgument',
        'identifier': identifier.toJson(),
        'value': value.toJson(),
      };
}
