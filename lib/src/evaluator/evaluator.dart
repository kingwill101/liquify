import 'package:liquify/parser.dart' show parseInput, Tag;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/drop.dart';
import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/tag_registry.dart';
import 'package:liquify/src/util.dart';

import '../ast.dart';
import '../buffer.dart';
import '../visitor.dart';

part 'buffer.dart';
part 'evaluate.dart';
part 'visit.dart';
part 'visit_async.dart';

/// Evaluates Liquid templates by traversing and executing AST nodes.
///
/// The evaluator maintains a [context] for variable storage and a [buffer] for
/// accumulating output during template rendering. It implements the visitor pattern
/// through [ASTVisitor] to evaluate different types of AST nodes.
class Evaluator implements ASTVisitor<dynamic> {
  final Environment context;
  Buffer buffer = Buffer();
  final List<Buffer> _blockBuffers = [];
  final Map<String, ASTNode> nodeMap = {};

  Evaluator(this.context);

  /// Creates a new `Evaluator` instance with the provided `Environment` context and `Buffer`.
  Evaluator.withBuffer(this.context, this.buffer);

  /// Creates a new `Evaluator` instance with a cloned `Environment` context and the same `Buffer`.
  Evaluator createInnerEvaluator() {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  tmpResult(List<ASTNode> nodes) {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, Buffer()).evaluateNodes(nodes);
  }

  tmpResultAsync(List<ASTNode> nodes) async {
    final innerContext = context.clone();
    return await Evaluator.withBuffer(innerContext, Buffer())
        .evaluateNodesAsync(nodes);
  }

  /// Creates a nested evaluator with a cloned context and the given [buffer].
  Evaluator createInnerEvaluatorWithBuffer(Buffer buffer) {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  @override
  dynamic visitLiteral(Literal node) {
    return node.value;
  }

  @override
  dynamic visitIdentifier(Identifier node) {
    final value = context.getVariable(node.name);
    return value;
  }

  dynamic _binaryOp(left, operator, right) {
    switch (operator) {
      case '+':
        if (left is String || right is String) {
          return '${left ?? ''}${(right ?? '')}';
        }
        return (left ?? 0) + (right ?? 0);
      case '-':
        return (left ?? 0) - (right ?? 0);
      case '*':
        return (left ?? 1) * (right ?? 1);
      case '/':
        return (left ?? 1) / (right ?? 1);
      case '==':
        return left == right;
      case '!=':
        return left != right;
      case '<':
        return (left ?? 0) < (right ?? 0);
      case '>':
        return (left ?? 0) > (right ?? 0);
      case '<=':
        return (left ?? 0) <= (right ?? 0);
      case '>=':
        return (left ?? 0) >= (right ?? 0);
      case 'and':
        return isTruthy(left) && isTruthy(right);
      case 'or':
        return isTruthy(left) || isTruthy(right);
      case '..':
        return List.generate(
            (right ?? 0) - (left ?? 0) + 1, (index) => (left ?? 0) + index);
      case 'in':
        if (right is! Iterable) {
          throw Exception('Right side of "in" operator must be iterable.');
        }
        return right.contains(left);
      case 'contains':
        if (left is String && right is String) {
          return left.contains(right);
        } else if (left is Iterable && right is String) {
          return left.contains(right);
        }
        throw Exception(
            'contains operator requires string or iterable on left side and string on right side');
      default:
        throw UnsupportedError('Unsupported operator: $operator');
    }
  }

  @override
  dynamic visitBinaryOperation(BinaryOperation node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);

    return _binaryOp(left, node.operator, right);
  }

  @override
  dynamic visitUnaryOperation(UnaryOperation node) {
    final expr = node.expression.accept(this);
    switch (node.operator) {
      case 'not':
      case '!':
        return !expr;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
  }

  @override
  dynamic visitGroupedExpression(GroupedExpression node) {
    return node.expression.accept(this);
  }

  @override
  dynamic visitAssignment(Assignment node) {
    final value = node.value.accept(this);
    if (node.variable is Identifier) {
      context.setVariable((node.variable as Identifier).name, value);
    } else if (node.variable is MemberAccess) {
      final memberAccess = node.variable as MemberAccess;
      final objName = (memberAccess.object as Identifier).name;

      if (context.getVariable(objName) == null) {
        context.setVariable(objName, {});
      }

      var objectVal = context(objName);
      for (var i = 0; i < memberAccess.members.length; i++) {
        final name = (memberAccess.members[i] as Identifier).name;
        if (i == memberAccess.members.length - 1) {
          objectVal[name] = value;
        } else {
          if (!(objectVal as Map).containsKey(memberAccess.members[i])) {
            objectVal[name] = {};
          }
          objectVal = objectVal[name];
        }
      }
    }
  }

  @override
  dynamic visitDocument(Document node) {
    return evaluateNodes(node.children);
  }

  @override
  dynamic visitFilter(Filter node) {
    final filterFunction = context.getFilter(node.name.name);
    if (filterFunction == null) {
      throw Exception('Undefined filter: ${node.name.name}');
    }

    final args = <dynamic>[];
    final namedArgs = <String, dynamic>{};

    for (final arg in node.arguments) {
      if (arg is NamedArgument) {
        namedArgs[arg.identifier.name] = arg.value.accept(this);
      } else {
        args.add(arg.accept(this));
      }
    }

    return (value) => filterFunction(value, args, namedArgs);
  }

  @override
  dynamic visitFilterExpression(FilteredExpression node) {
    dynamic value;
    if (node.expression is Assignment) {
      (node.expression as Assignment).value.accept(this);
      if ((node.expression as Assignment).value is Literal) {
        value = ((node.expression as Assignment).value as Literal).value;
      } else {
        value = context.getVariable(
            ((node.expression as Assignment).value as Identifier).name);
      }
    } else {
      value = node.expression.accept(this);
    }

    for (final filter in node.filters) {
      final filterFunction = filter.accept(this);
      value = filterFunction(value);
    }
    return value;
  }

  @override
  dynamic visitMemberAccess(MemberAccess node) {
    var object = node.object;
    final objName = (object as Identifier).name;
    var objectVal = context.getVariable(objName);

    if (objectVal == null) return null;

    for (final member in node.members) {
      final keyName = member is Identifier
          ? member.name
          : ((member as ArrayAccess).array as Identifier).name;
      final isArray = member is ArrayAccess;

      if (isArray) {
        final key = (member.array as Identifier).name;
        final index = (member.key as Literal).value;
        objectVal = objectVal[key];

        if (objectVal == null) return;
        if (objectVal is List) {
          if (index >= 0 && index < objectVal.length) {
            objectVal = objectVal[index];
          } else {
            return null;
          }
        } else {
          objectVal = objectVal[index];
        }
      } else if (objectVal is Drop) {
        if (member is Identifier) {
          objectVal = objectVal(Symbol(keyName));
        }
      } else if (objectVal is List && member is Identifier) {
        // Check if it's a registered dot notation filter
        if (FilterRegistry.isDotNotationFilter(keyName)) {
          final filterFunction = FilterRegistry.getFilter(keyName);
          if (filterFunction != null) {
            objectVal = filterFunction(objectVal, [], {});
          }
        }
      } else if (objectVal is Map) {
        if (!objectVal.containsKey(keyName)) {
          return null;
        }
        objectVal = objectVal[keyName];
      } else if (objectVal == null) {
        return null;
      }
    }
    return objectVal;
  }

  @override
  dynamic visitNamedArgument(NamedArgument node) {
    return MapEntry(node.identifier.name, node.value.accept(this));
  }

  @override
  dynamic visitTag(Tag node) {
    final tag = TagRegistry.createTag(node.name, node.content, node.filters);
    tag?.preprocess(this);
    tag?.body = node.body;
    tag?.evaluate(this, buffer);
  }

  @override
  dynamic visitTextNode(TextNode node) {
    return node.text;
  }

  @override
  dynamic visitVariable(Variable node) {
    return node.expression.accept(this);
  }

  @override
  visitArrayAccess(ArrayAccess arrayAccess) {
    final array = arrayAccess.array.accept(this);
    final key = arrayAccess.key.accept(this);
    if (array is List) {
      final index = key is int ? key : int.parse(key);
      if (index >= 0 && index < array.length) {
        return array[index];
      }
    } else if (array is Map && array.containsKey(key)) {
      return array[key];
    }
    return null;
  }

  @override
  Future<dynamic> visitArrayAccessAsync(ArrayAccess arrayAccess) async {
    final array = await arrayAccess.array.acceptAsync(this);
    final key = await arrayAccess.key.acceptAsync(this);
    if (array is List) {
      final index = key is int ? key : int.parse(key);
      if (index >= 0 && index < array.length) {
        return array[index];
      }
    } else if (array is Map && array.containsKey(key)) {
      return array[key];
    }
    return null;
  }

  @override
  Future<dynamic> visitAssignmentAsync(Assignment node) async {
    final value = await node.value.acceptAsync(this);
    if (node.variable is Identifier) {
      context.setVariable((node.variable as Identifier).name, value);
    } else if (node.variable is MemberAccess) {
      final memberAccess = node.variable as MemberAccess;
      final objName = (memberAccess.object as Identifier).name;

      if (context.getVariable(objName) == null) {
        context.setVariable(objName, {});
      }

      var objectVal = context(objName);
      for (var i = 0; i < memberAccess.members.length; i++) {
        final name = (memberAccess.members[i] as Identifier).name;
        if (i == memberAccess.members.length - 1) {
          objectVal[name] = value;
        } else {
          if (!(objectVal as Map).containsKey(memberAccess.members[i])) {
            objectVal[name] = {};
          }
          objectVal = objectVal[name];
        }
      }
    }
  }

  @override
  Future<dynamic> visitBinaryOperationAsync(BinaryOperation node) async {
    final left = await node.left.acceptAsync(this);
    final right = await node.right.acceptAsync(this);
    return _binaryOp(left, node.operator, right);
  }

  @override
  Future<dynamic> visitDocumentAsync(Document node) async {
    return await evaluateNodesAsync(node.children);
  }

  @override
  Future<dynamic> visitFilterAsync(Filter node) async {
    final filterFunction = context.getFilter(node.name.name);
    if (filterFunction == null) {
      throw Exception('Undefined filter: ${node.name.name}');
    }
    final args = <dynamic>[];
    final namedArgs = <String, dynamic>{};

    for (final arg in node.arguments) {
      if (arg is NamedArgument) {
        namedArgs[arg.identifier.name] = await arg.value.acceptAsync(this);
      } else {
        args.add(await arg.acceptAsync(this));
      }
    }

    return (value) => filterFunction(value, args, namedArgs);
  }

  @override
  Future<dynamic> visitFilterExpressionAsync(FilteredExpression node) async {
    dynamic value;
    if (node.expression is Assignment) {
      await (node.expression as Assignment).value.acceptAsync(this);
      if ((node.expression as Assignment).value is Literal) {
        value = ((node.expression as Assignment).value as Literal).value;
      } else {
        value = context.getVariable(
            ((node.expression as Assignment).value as Identifier).name);
      }
    } else {
      value = await node.expression.acceptAsync(this);
    }

    for (final filter in node.filters) {
      final filterFunction = await filter.acceptAsync(this);
      value = filterFunction(value);
    }
    return value;
  }

  @override
  Future<dynamic> visitGroupedExpressionAsync(GroupedExpression node) async {
    return await node.expression.acceptAsync(this);
  }

  @override
  Future<dynamic> visitIdentifierAsync(Identifier node) async {
    return context.getVariable(node.name);
  }

  @override
  Future<dynamic> visitLiteralAsync(Literal node) async {
    return node.value;
  }

  @override
  Future<dynamic> visitMemberAccessAsync(MemberAccess node) async {
    var object = node.object;
    final objName = (object as Identifier).name;
    var objectVal = context.getVariable(objName);

    if (objectVal == null) return null;

    for (final member in node.members) {
      final keyName = member is Identifier
          ? member.name
          : ((member as ArrayAccess).array as Identifier).name;
      final isArray = member is ArrayAccess;

      if (isArray) {
        final key = (member.array as Identifier).name;
        final index = (member.key as Literal).value;
        objectVal = objectVal[key];

        if (objectVal == null) return;
        if (objectVal is List) {
          if (index >= 0 && index < objectVal.length) {
            objectVal = objectVal[index];
          } else {
            return null;
          }
        } else {
          objectVal = objectVal[index];
        }
      } else if (objectVal is Drop) {
        if (member is Identifier) {
          objectVal = objectVal(Symbol(keyName));
        }
      } else if (objectVal is List && member is Identifier) {
        // Check if it's a registered dot notation filter
        if (FilterRegistry.isDotNotationFilter(keyName)) {
          final filterFunction = FilterRegistry.getFilter(keyName);
          if (filterFunction != null) {
            objectVal = await filterFunction(objectVal, [], {});
          }
        }
      } else if (objectVal is Map) {
        if (!objectVal.containsKey(keyName)) {
          return null;
        }
        objectVal = objectVal[keyName];
      } else if (objectVal == null) {
        return null;
      }
    }
    return objectVal;
  }

  @override
  Future<dynamic> visitNamedArgumentAsync(NamedArgument node) async {
    return MapEntry(node.identifier.name, await node.value.acceptAsync(this));
  }

  @override
  Future<dynamic> visitTagAsync(Tag node) async {
    final tag = TagRegistry.createTag(node.name, node.content, node.filters);
    tag?.preprocess(this);
    tag?.body = node.body;
    await tag?.evaluateAsync(this, buffer);
  }

  @override
  Future<dynamic> visitTextNodeAsync(TextNode node) async {
    return node.text;
  }

  @override
  Future<dynamic> visitUnaryOperationAsync(UnaryOperation node) async {
    final expr = await node.expression.acceptAsync(this);
    switch (node.operator) {
      case 'not':
      case '!':
        return !expr;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
  }

  @override
  Future<dynamic> visitVariableAsync(Variable node) async {
    return node.expression.acceptAsync(this);
  }
}
