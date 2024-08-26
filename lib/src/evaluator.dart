import 'package:liquify/parser.dart' show parseInput;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/drop.dart';
import 'package:liquify/src/tag_registry.dart';

import 'ast.dart';
import 'buffer.dart';
import 'visitor.dart';

/// The `Evaluator` class is responsible for evaluating Liquid templates.
/// It provides methods to resolve and parse templates, as well as evaluate
/// individual AST nodes and a list of nodes.
/// The `Evaluator` class takes an `Environment` context and an optional `Buffer`
/// instance, which are used during the evaluation process.
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

  @override

  /// Evaluates a literal AST node by returning its value.
  ///
  /// This method is part of the `Evaluator` class, which is responsible for evaluating the various types of AST nodes that represent a Liquid template. When the `Evaluator` encounters a `Literal` node, it simply returns the value of that node, as literals represent constant values in the template.
  ///
  /// @param node The `Literal` AST node to evaluate.
  /// @return The value of the `Literal` node.
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
        result = left && right;
        break;
      case 'or':
        result = left || right;
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
        if (i == memberAccess.members.length - 1) {
          objectVal[memberAccess.members[i]] = value;
        } else {
          if (!(objectVal as Map).containsKey(memberAccess.members[i])) {
            objectVal[memberAccess.members[i]] = {};
          }
          objectVal = objectVal[memberAccess.members[i]];
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

    if (context.getVariable(objName) == null) return null;

    var objectVal = context.getVariable(objName);

    for (final member in node.members) {
      if (objectVal is Drop) {
        objectVal = objectVal(Symbol(member));
      } else if (objectVal is Map && objectVal.containsKey(member)) {
        objectVal = objectVal[member];
      } else if (objectVal is List && int.tryParse(member) != null) {
        final index = int.parse(member);
        if (index >= 0 && index < objectVal.length) {
          objectVal = objectVal[index];
        } else {
          return null;
        }
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
}
