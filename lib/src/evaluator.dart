import 'package:liquify/parser.dart' show parseInput;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/drop.dart';
import 'package:liquify/src/tag_registry.dart';
import 'package:liquify/src/util.dart';

import 'ast.dart';
import 'buffer.dart';
import 'visitor.dart';

/// Evaluates Liquid templates by traversing and executing AST nodes.
///
/// The evaluator maintains a [context] for variable storage and a [buffer] for
/// accumulating output during template rendering. It implements the visitor pattern
/// through [ASTVisitor] to evaluate different types of AST nodes.
///
/// Example:
/// ```dart
/// final evaluator = Evaluator(Environment());
/// final nodes = parseInput('Hello {{ name }}!');
/// evaluator.context.setVariable('name', 'World');
/// final result = evaluator.evaluateNodes(nodes);
/// print(result); // Prints: Hello World!
/// ```
class Evaluator implements ASTVisitor<dynamic> {
  final Environment context;
  Buffer buffer = Buffer();
  final Map<String, ASTNode> nodeMap = {};

  Evaluator(this.context);

  /// Creates a new `Evaluator` instance with the provided `Environment` context and `Buffer`.
  /// The `Buffer` is used to accumulate the output of the template evaluation.
  Evaluator.withBuffer(this.context, this.buffer);

  /// Creates a new `Evaluator` instance with a cloned `Environment` context and the same `Buffer`.
  /// This allows creating a nested `Evaluator` instance with its own context, while sharing the same output buffer.
  Evaluator createInnerEvaluator() {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  /// Creates a nested evaluator with a cloned context and the given [buffer].
  ///
  /// Useful for evaluating nested templates that need their own variable scope
  /// while sharing the same output buffer.
  ///
  /// ```dart
  /// final inner = evaluator.createInnerEvaluatorWithBuffer(Buffer());
  /// inner.context.setVariable('x', 123); // Won't affect parent context
  /// ```
  Evaluator createInnerEvaluatorWithBuffer(Buffer buffer) {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  /// Resolves and parses the Liquid template with the given name.
  ///
  /// The template is resolved relative to the root directory set in the `Environment` context.
  /// If no root directory is set, an exception is thrown.
  ///
  /// The content of the resolved template file is parsed into a list of `ASTNode` instances.
  ///
  /// @param templateName The name of the Liquid template to resolve and parse.
  /// @return A list of `ASTNode` instances representing the parsed template.
  /// @throws Exception if no root directory is set for template resolution.
  List<ASTNode> resolveAndParseTemplate(String templateName) {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }

    final source = root.resolve(templateName);
    return parseInput(source.content);
  }

  /// Resolves and parses a template asynchronously.
  ///
  /// Use this instead of [resolveAndParseTemplate] when loading templates from
  /// remote sources or slow storage. Throws if no root directory is set.
  Future<List<ASTNode>> resolveAndParseTemplateAsync(
      String templateName) async {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }
    final source = await root.resolveAsync(templateName);
    return parseInput(source.content);
  }

  /// Evaluates the provided AST node by calling its `accept` method with this `Evaluator` instance.
  ///
  /// This method is used to evaluate individual AST nodes during the template evaluation process.
  /// It delegates the evaluation of the node to the node's own `accept` method, passing in the current `Evaluator` instance.
  ///
  /// @param node The AST node to evaluate.
  /// @return The result of evaluating the AST node.
  dynamic evaluate(ASTNode node) {
    return node.accept(this);
  }

  /// Evaluates the provided AST node asynchronously by calling its `acceptAsync` method with this `Evaluator` instance.
  ///
  /// This method is used to evaluate individual AST nodes during the template evaluation process asynchronously.
  /// It delegates the evaluation of the node to the node's own `acceptAsync` method, passing in the current `Evaluator` instance.
  ///
  /// @param node The AST node to evaluate.
  /// @return The result of evaluating the AST node.
  Future<dynamic> evaluateAsync(ASTNode node) {
    return node.acceptAsync(this);
  }

  /// Evaluates a list of AST nodes and writes the results to the buffer.
  ///
  /// This method iterates through the provided list of AST nodes and evaluates each one.
  /// For `Assignment` nodes, the method simply continues to the next node.
  /// For `Tag` nodes, the method calls the `accept` method on the node, allowing the node to handle its own evaluation.
  /// For all other node types, the method writes the result of evaluating the node to the buffer.
  ///
  /// After evaluating all the nodes, the method returns the contents of the buffer as a string.
  ///
  /// @param nodes The list of AST nodes to evaluate.
  /// @return The contents of the buffer as a string, representing the evaluated nodes.
  dynamic evaluateNodes(List<ASTNode> nodes) {
    for (final node in nodes) {
      if (node is Assignment) continue;
      if (node is Tag) {
        node.accept(this);
      } else {
        buffer.write(node.accept(this));
      }
    }
    return buffer.toString();
  }

  /// Evaluates a list of AST nodes asynchronously and writes the results to the buffer.
  ///
  /// This method iterates through the provided list of AST nodes and evaluates each one asynchronously.
  /// For `Assignment` nodes, the method simply continues to the next node.
  /// For `Tag` nodes, the method calls the `acceptAsync` method on the node, allowing the node to handle its own evaluation.
  /// For all other node types, the method writes the result of evaluating the node to the buffer.
  ///
  /// After evaluating all the nodes, the method returns the contents of the buffer as a string.
  ///
  /// @param nodes The list of AST nodes to evaluate.
  /// @return The contents of the buffer as a string, representing the evaluated nodes.
  Future<dynamic> evaluateNodesAsync(List<ASTNode> nodes) async {
    for (final node in nodes) {
      if (node is Assignment) continue;
      if (node is Tag) {
        await node.acceptAsync(this);
      } else {
        buffer.write(await node.acceptAsync(this));
      }
    }
    return buffer.toString();
  }

  @override

  /// Returns the raw value stored in the [Literal] node.
  ///
  /// Values can be strings, numbers, booleans, null, etc.
  dynamic visitLiteral(Literal node) {
    return node.value;
  }

  @override
  dynamic visitIdentifier(Identifier node) {
    final value = context.getVariable(node.name);
    return value;
  }

  @override
  dynamic visitBinaryOperation(BinaryOperation node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);
    dynamic result;
    switch (node.operator) {
      case '+':
        result = left + right;
        break;
      case '-':
        result = left - right;
        break;
      case '*':
        result = left * right;
        break;
      case '/':
        result = left / right;
        break;
      case '==':
        result = left == right;
        break;
      case '!=':
        result = left != right;
        break;
      case '<':
        result = left < right;
        break;
      case '>':
        result = left > right;
        break;
      case '<=':
        result = left <= right;
        break;
      case '>=':
        result = left >= right;
        break;
      case 'and':
        result = isTruthy(left) && isTruthy(right);
        break;
      case 'or':
        result = isTruthy(left) || isTruthy(right);
        break;
      case '..':
        result = List.generate(right - left + 1, (index) => left + index);
        break;
      case 'in':
        if (right is! Iterable) {
          throw Exception('Right side of "in" operator must be iterable.');
        }
        result = right.contains(left);
        break;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
    return result;
  }

  @override
  dynamic visitUnaryOperation(UnaryOperation node) {
    final expr = node.expression.accept(this);
    dynamic result;
    switch (node.operator) {
      case 'not':
      case '!':
        result = !expr;
        break;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
    return result;
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

    //members can either be a Identifier or an ArrayAccess
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
    final value = node.expression.accept(this);
    return value;
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
    dynamic result;
    switch (node.operator) {
      case '+':
        result = left + right;
        break;
      case '-':
        result = left - right;
        break;
      case '*':
        result = left * right;
        break;
      case '/':
        result = left / right;
        break;
      case '==':
        result = left == right;
        break;
      case '!=':
        result = left != right;
        break;
      case '<':
        result = left < right;
        break;
      case '>':
        result = left > right;
        break;
      case '<=':
        result = left <= right;
        break;
      case '>=':
        result = left >= right;
        break;
      case 'and':
        result = isTruthy(left) && isTruthy(right);
        break;
      case 'or':
        result = isTruthy(left) || isTruthy(right);
        break;
      case '..':
        result = List.generate(right - left + 1, (index) => left + index);
        break;
      case 'in':
        if (right is! Iterable) {
          throw Exception('Right side of "in" operator must be iterable.');
        }
        result = right.contains(left);
        break;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
    return result;
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
    final value = context.getVariable(node.name);
    return value;
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

    //members can either be a Identifier or an ArrayAccess
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
    dynamic result;
    switch (node.operator) {
      case 'not':
      case '!':
        result = !expr;
        break;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
    return result;
  }

  @override
  Future<dynamic> visitVariableAsync(Variable node) async {
    final value = await node.expression.acceptAsync(this);
    return value;
  }
}
