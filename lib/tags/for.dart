import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/exceptions.dart';
import 'package:liquid_grammar/tag.dart';

class ForTag extends BaseTag {
  ForTag(super.content, super.filters);

  @override
  bool get hasEndTag => true;

  late String variableName;
  late List<dynamic> iterable;
  int? limit;
  int? offset;
  bool reversed = false;

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! BinaryOperation) {
      throw Exception('ForTag requires a binary operation.');
    }

    final binaryOperation = content.first as BinaryOperation;
    if (binaryOperation.operator != 'in') {
      throw Exception('ForTag requires an "in" binary operation.');
    }

    final left = binaryOperation.left;
    final right = binaryOperation.right;

    if (left is! Identifier) {
      throw Exception(
          'ForTag requires an identifier on the left side of "in".');
    }

    variableName = left.name;

    if (right is BinaryOperation && right.operator == '..') {
      final start = evaluator.evaluate(right.left);
      final end = evaluator.evaluate(right.right);
      iterable = List.generate(end - start + 1, (index) => start + index);
    } else {
      iterable = evaluator.evaluate(right);
    }

    // Process filters for limit, offset, and reversed
    for (final arg in namedArgs) {
      if (arg.name.name == 'limit') {
        limit = evaluator.evaluate(arg.value);
      } else if (arg.name.name == 'offset') {
        offset = evaluator.evaluate(arg.value);
      }
    }

    for (final arg in args) {
      if (arg.name == 'reversed') {
        reversed = true;
      }
    }

    // Apply offset
    if (offset != null) {
      iterable = iterable.skip(offset!).toList();
    }

    // Apply limit
    if (limit != null) {
      iterable = iterable.take(limit!).toList();
    }

    // Apply reversed
    if (reversed) {
      iterable = iterable.reversed.toList();
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, StringBuffer buffer) {
    if (iterable.isEmpty) {
      // Walk backwards to find the else block
      bool elseBlockFound = false;
      var elseBlock = [];
      for (int i = body.length - 1; i >= 0; i--) {
        final node = body[i];
        if (node is Tag && node.name == 'else') {
          elseBlockFound = true;
          break;
        } else {
          elseBlock.add(node);
        }
      }
      if (elseBlockFound) {
        for (final node in elseBlock.reversed) {
          buffer.write(evaluator.evaluate(node));
        }
      }
    } else {
      for (final item in iterable) {
        evaluator.context.setVariable(variableName, item);
        for (final node in body) {
          if (node is Tag && node.name == 'else') {
            break;
          }
          try {
            buffer.write(evaluator.evaluate(node));
          } on BreakException {
            return buffer.toString();
          } on ContinueException {
            break;
          }
        }
      }
    }
    return buffer.toString();
  }
}
