import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';

class ForLoopObject {
  final int length;
  final ForLoopObject? parentloop;
  int index;
  int index0;
  int rindex;
  int rindex0;
  bool first;
  bool last;

  ForLoopObject({
    required this.length,
    this.parentloop,
    this.index = 1,
    this.index0 = 0,
  })  : rindex = length,
        rindex0 = length - 1,
        first = true,
        last = length == 1;

  void increment() {
    index++;
    index0++;
    rindex--;
    rindex0--;
    first = false;
    last = index == length;
  }

  Map<String, dynamic> toMap() {
    return {
      'length': length,
      'parentloop': parentloop?.toMap(),
      'index': index,
      'index0': index0,
      'rindex': rindex,
      'rindex0': rindex0,
      'first': first,
      'last': last,
    };
  }

  ForLoopObject.fromJson(Map<String, dynamic> json)
      : length = json['length'],
        parentloop = json['parentloop'] != null
            ? ForLoopObject.fromJson(json['parentloop'])
            : null,
        index = json['index'],
        index0 = json['index0'],
        rindex = json['rindex'],
        rindex0 = json['rindex0'],
        first = json['first'],
        last = json['last'];
}

class ForTag extends AbstractTag {
  ForTag(super.content, super.filters);

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
      if (arg.identifier.name == 'limit') {
        limit = evaluator.evaluate(arg.value);
      } else if (arg.identifier.name == 'offset') {
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
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (iterable.isEmpty) {
      final elseBlock =
          body.where((ASTNode node) => node is Tag && node.name == 'else');

      if (elseBlock.isNotEmpty) {
        final block = elseBlock.first as Tag;
        for (final node in block.body) {
          if (node is Tag) {
            evaluator.evaluate(node);
          } else {
            buffer.write(evaluator.evaluate(node));
          }
        }
      }
    } else {
      final parentForLoop =
          evaluator.context.getVariable('forloop') as Map<String, dynamic>?;
      final forLoop = ForLoopObject(
          length: iterable.length,
          parentloop: parentForLoop == null
              ? null
              : ForLoopObject.fromJson(parentForLoop));

      evaluator.context.pushScope();

      for (final item in iterable) {
        evaluator.context.setVariable('forloop', forLoop.toMap());
        evaluator.context.setVariable(variableName, item);

        try {
          for (final node in body) {
            if (node is Tag && node.name == 'else') {
              break;
            }
            try {
              buffer.write(evaluator.evaluate(node));
            } on BreakException {
              evaluator.context.popScope();
              return;
            } on ContinueException {
              break;
            }
          }
        } on ContinueException {
          // Do nothing, just continue to the next iteration
        }

        forLoop.increment();
      }

      evaluator.context.popScope();
    }
  }
}
