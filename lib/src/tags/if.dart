import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/util.dart';

class IfTag extends AbstractTag {
  bool conditionMet = false;

  IfTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    conditionMet = isTruthy(evaluator.evaluate(content[0]));

    final elseBlock = body.where((ASTNode n) {
      return n is Tag && n.name == 'else';
    }).firstOrNull;

    if (conditionMet) {
      for (final subNode in body) {
        if (subNode is Tag && subNode.name == 'else') {
          break;
        }
        try {
          if (subNode is Tag) {
            evaluator.evaluate(subNode);
          } else {
            buffer.write(evaluator.evaluate(subNode));
          }
        } on BreakException {
          throw BreakException();
        } on ContinueException {
          throw ContinueException();
        }
      }
    } else if (elseBlock != null) {
      for (final subNode in (elseBlock as Tag).body) {
        try {
          if (subNode is Tag) {
            evaluator.evaluate(subNode);
          } else {
            buffer.write(evaluator.evaluate(subNode));
          }
        } on BreakException {
          throw BreakException();
        } on ContinueException {
          throw ContinueException();
        }
      }
    }
  }
}
