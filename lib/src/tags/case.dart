import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class CaseTag extends AbstractTag {
  late dynamic caseValue;

  CaseTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty) {
      throw Exception('CaseTag requires a value to switch on.');
    }
    caseValue = evaluator.evaluate(content[0]);
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    Tag? elseTag;
    bool matchFound = false;

    for (final node in body) {
      if (node is Tag) {
        if (node.name == 'when' && !matchFound) {
          final whenValues =
              node.content.map((e) => evaluator.evaluate(e)).toList();
          if (whenValues.contains(caseValue)) {
            _evaluateBody(node.body, evaluator, buffer);
            matchFound = true;
          }
        } else if (node.name == 'else') {
          elseTag = node;
        }
      }
    }

    if (!matchFound && elseTag != null) {
      _evaluateBody(elseTag.body, evaluator, buffer);
    }
  }

  void _evaluateBody(
      List<ASTNode> nodeBody, Evaluator evaluator, Buffer buffer) {
    for (final subNode in nodeBody) {
      if (subNode is Tag) {
        evaluator.evaluate(subNode);
      } else {
        buffer.write(evaluator.evaluate(subNode));
      }
    }
  }
}
