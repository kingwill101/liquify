import 'package:liquify/parser.dart' show parseInput, Tag;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/drop.dart';
import 'package:liquify/src/filter_registry.dart';
import 'package:liquify/src/liquid_number.dart';
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

  String tmpResult(List<ASTNode> nodes) {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, Buffer()).evaluateNodes(nodes);
  }

  Future tmpResultAsync(List<ASTNode> nodes) async {
    final innerContext = context.clone();
    return await Evaluator.withBuffer(
      innerContext,
      Buffer(),
    ).evaluateNodesAsync(nodes);
  }

  /// Creates a nested evaluator with a cloned context and the given [buffer].
  Evaluator createInnerEvaluatorWithBuffer(Buffer buffer) {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  /// Runs an action using the provided buffer, restoring the previous buffer afterward.
  T withBuffer<T>(
    Buffer newBuffer,
    T Function() action, {
    bool clearBuffer = true,
  }) {
    final previousBuffer = buffer;
    final previousBlocks = List<Buffer>.from(_blockBuffers);
    buffer = newBuffer;
    _blockBuffers.clear();
    try {
      final result = action();
      if (clearBuffer) {
        buffer.clear();
      }
      return result;
    } finally {
      buffer = previousBuffer;
      _blockBuffers
        ..clear()
        ..addAll(previousBlocks);
    }
  }

  /// Runs an async action using the provided buffer, restoring the previous buffer afterward.
  Future<T> withBufferAsync<T>(
    Buffer newBuffer,
    Future<T> Function() action, {
    bool clearBuffer = true,
  }) async {
    final previousBuffer = buffer;
    final previousBlocks = List<Buffer>.from(_blockBuffers);
    buffer = newBuffer;
    _blockBuffers.clear();
    try {
      final result = await action();
      if (clearBuffer) {
        buffer.clear();
      }
      return result;
    } finally {
      buffer = previousBuffer;
      _blockBuffers
        ..clear()
        ..addAll(previousBlocks);
    }
  }

  @override
  dynamic visitLiteral(Literal node) {
    final value = node.value;
    return node.isDecimal && value is double
        ? preserveLiquidDecimal(value)
        : value;
  }

  @override
  dynamic visitIdentifier(Identifier node) {
    final value = context.getVariable(node.name);
    return value;
  }

  dynamic _binaryOp(dynamic left, String op, dynamic right) {
    if (op == '+' && (left is String || right is String)) {
      return '${left ?? ''}${right ?? ''}';
    }
    final isDecimal =
        left is LiquidDecimal ||
        right is LiquidDecimal ||
        (left is double && left is! int) ||
        (right is double && right is! int);
    left = unwrapLiquidNumber(left);
    right = unwrapLiquidNumber(right);

    dynamic numericResult(dynamic result) =>
        isDecimal && result is double ? preserveLiquidDecimal(result) : result;

    switch (op) {
      case '+':
        return numericResult((left ?? 0) + (right ?? 0));
      case '-':
        return numericResult((left ?? 0) - (right ?? 0));
      case '*':
        return numericResult((left ?? 1) * (right ?? 1));
      case '/':
        return numericResult((left ?? 1) / (right ?? 1));
      case '==':
        return liquidEquals(left, right);
      case '!=':
        return !liquidEquals(left, right);
      case '<':
        final comparison = _compare(left, right);
        return comparison != null && comparison < 0;
      case '>':
        final comparison = _compare(left, right);
        return comparison != null && comparison > 0;
      case '<=':
        final comparison = _compare(left, right);
        return comparison != null && comparison <= 0;
      case '>=':
        final comparison = _compare(left, right);
        return comparison != null && comparison >= 0;
      case 'and':
        return isTruthy(left) && isTruthy(right);
      case 'or':
        return isTruthy(left) || isTruthy(right);
      case '..':
        final start = left ?? 0;
        final end = right ?? 0;
        if (end < start) return [];
        return List.generate(end - start + 1, (index) => start + index);
      case 'in':
        if (right is! Iterable) {
          throw Exception('Right side of "in" operator must be iterable.');
        }
        return right.contains(left);
      case 'contains':
        if (!isTruthy(right)) return false;
        return switch (left) {
          String() => left.contains(right.toString()),
          Iterable() => left.contains(right),
          Map() => left.containsKey(right),
          _ => false,
        };
      default:
        throw UnsupportedError('Unsupported operator: $op');
    }
  }

  @override
  dynamic visitBinaryOperation(BinaryOperation node) {
    final left = node.left.accept(this);
    if (node.operator == 'and' && !isTruthy(left)) return false;
    if (node.operator == 'or' && isTruthy(left)) return true;
    final right = node.right.accept(this);

    return _binaryOp(left, node.operator, right);
  }

  @override
  dynamic visitUnaryOperation(UnaryOperation node) {
    final expr = node.expression.accept(this);
    switch (node.operator) {
      case 'not':
      case '!':
        return !isTruthy(expr);
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

    return (value) =>
        _applyFilter(node.name.name, filterFunction, value, args, namedArgs);
  }

  @override
  dynamic visitFilterExpression(FilteredExpression node) {
    final expression = node.expression;
    final operand = expression is Assignment ? expression.value : expression;
    var value = operand.accept(this);

    for (final filter in node.filters) {
      final filterFunction = filter.accept(this);
      value = filterFunction(value);
    }
    return value;
  }

  @override
  dynamic visitMemberAccess(MemberAccess node) {
    var value = node.object.accept(this);
    for (final member in node.members) {
      if (value == null) return null;
      value = _resolveMember(value, member, (key) => key.accept(this));
    }
    return value;
  }

  dynamic _resolveMember(
    Object? value,
    ASTNode member,
    Object? Function(ASTNode) evaluateKey,
  ) => switch (member) {
    Identifier(:final name) => _lookupMember(value, name),
    ArrayAccess(:final array, :final key) => _lookupIndex(
      _resolveMember(value, array, evaluateKey),
      evaluateKey(key),
    ),
    _ => null,
  };

  @override
  dynamic visitNamedArgument(NamedArgument node) {
    return MapEntry(node.identifier.name, node.value.accept(this));
  }

  @override
  dynamic visitTag(Tag node) {
    // First try environment-scoped tags, then fall back to global registry
    final tagCreator = context.getTag(node.name);
    final tag = tagCreator != null
        ? tagCreator(node.content, node.filters)
        : TagRegistry.createTag(node.name, node.content, node.filters);
    tag?.preprocess(this);
    tag?.body = node.body;
    tag?.evaluate(this, currentBuffer);
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
  dynamic visitArrayAccess(ArrayAccess node) =>
      _lookupIndex(node.array.accept(this), node.key.accept(this));

  @override
  Future<dynamic> visitArrayAccessAsync(ArrayAccess node) async => _lookupIndex(
    await node.array.acceptAsync(this),
    await node.key.acceptAsync(this),
  );

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
    if (node.operator == 'and' && !isTruthy(left)) return false;
    if (node.operator == 'or' && isTruthy(left)) return true;
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

    return (value) =>
        _applyFilter(node.name.name, filterFunction, value, args, namedArgs);
  }

  @override
  Future<dynamic> visitFilterExpressionAsync(FilteredExpression node) async {
    final expression = node.expression;
    final operand = expression is Assignment ? expression.value : expression;
    var value = await operand.acceptAsync(this);

    for (final filter in node.filters) {
      final filterFunction = await filter.acceptAsync(this);
      final result = filterFunction(value);
      value = result is Future ? await result : result;
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
  Future<dynamic> visitLiteralAsync(Literal node) async => visitLiteral(node);

  @override
  Future<dynamic> visitMemberAccessAsync(MemberAccess node) async {
    var value = await node.object.acceptAsync(this);
    for (final member in node.members) {
      if (value == null) return null;
      value = await _resolveMemberAsync(value, member);
    }
    return value;
  }

  Future<dynamic> _resolveMemberAsync(Object? value, ASTNode member) async {
    if (member is Identifier) return _lookupMember(value, member.name);
    if (member is ArrayAccess) {
      final collection = await _resolveMemberAsync(value, member.array);
      return _lookupIndex(collection, await member.key.acceptAsync(this));
    }
    return null;
  }

  @override
  Future<dynamic> visitNamedArgumentAsync(NamedArgument node) async {
    return MapEntry(node.identifier.name, await node.value.acceptAsync(this));
  }

  @override
  Future<dynamic> visitTagAsync(Tag node) async {
    // First try environment-scoped tags, then fall back to global registry
    final tagCreator = context.getTag(node.name);
    final tag = tagCreator != null
        ? tagCreator(node.content, node.filters)
        : TagRegistry.createTag(node.name, node.content, node.filters);
    tag?.preprocess(this);
    tag?.body = node.body;
    await tag?.evaluateAsync(this, currentBuffer);
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
        return !isTruthy(expr);
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
  }

  @override
  Future<dynamic> visitVariableAsync(Variable node) async {
    return node.expression.acceptAsync(this);
  }
}
