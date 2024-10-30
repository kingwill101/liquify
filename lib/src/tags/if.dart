import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/util.dart';

class IfTag extends AbstractTag {
  bool conditionMet = false;

  IfTag(super.content, super.filters);

  renderBlock(Evaluator evaluator, Buffer buffer, List<ASTNode> body) {
    for (final subNode in body) {
      if (subNode is Tag && subNode.name == 'else') {
        continue;
      }
      if (subNode is Tag && subNode.name == 'elseif') {
        continue;
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
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    conditionMet = isTruthy(evaluator.evaluate(content[0]));

    final elseBlock = body.where((ASTNode n) {
      return n is Tag && n.name == 'else';
    }).firstOrNull;

    final List<Tag> elseIfTags = body
        .where((ASTNode n) {
          return n is Tag && n.name == "elseif";
        })
        .toList()
        .cast();

    if (conditionMet) {
      renderBlock(evaluator, buffer, body);
      return;
    } else if (elseIfTags.isNotEmpty) {
      for (var elif in elseIfTags) {
        if (elif.content.isEmpty) continue;
        final elIfConditionMet =
            isTruthy(evaluator.evaluate((elif).content[0]));
        if (elIfConditionMet) {
          renderBlock(evaluator, buffer, elif.body);
          return;
        }
      }
    }

    if (elseBlock != null) {
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
