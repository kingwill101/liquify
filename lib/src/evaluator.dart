import 'package:liquify/parser.dart' show parseInput;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/drop.dart';
import 'package:liquify/src/registry.dart';

import 'ast.dart';
import 'buffer.dart';
import 'visitor.dart';

class Evaluator implements ASTVisitor<dynamic> {
  final Environment context;
  Buffer buffer = Buffer();
  final Map<String, ASTNode> nodeMap = {};

  Evaluator(this.context);

  Evaluator.withBuffer(this.context, this.buffer);

  Evaluator createInnerEvaluator() {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  String resolveTemplate(String templateName) {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }

    final source = root.resolve(templateName);
    return source.content;
  }

  List<ASTNode> resolveAndParseTemplate(String templateName) {
    final root = context.getRoot();
    if (root == null) {
      throw Exception('No root directory set for template resolution');
    }

    final source = root.resolve(templateName);
    return parseInput(source.content);
  }

  dynamic evaluate(ASTNode node) {
    return node.accept(this);
  }

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
      value = context.getVariable(
          ((node.expression as Assignment).value as Identifier).name);
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
