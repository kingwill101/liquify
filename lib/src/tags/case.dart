import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class CaseTag extends AbstractTag {
  late dynamic caseValue;

  CaseTag(super.content, super.filters);

  @override
  Future<void> preprocess(Evaluator evaluator) async {
    if (content.isEmpty) {
      throw Exception('CaseTag requires a value to switch on.');
    }
    caseValue = await evaluator.evaluate(content[0]);
  }

  @override
  Future<dynamic> evaluateWithContext(
      Evaluator evaluator, Buffer buffer) async {
    Tag? elseTag;
    bool matchFound = false;

    for (final node in body) {
      if (node is Tag) {
        if (node.name == 'when' && !matchFound) {
          final whenValues = node.content.map((e) async => await evaluator.evaluate(e));
          if (whenValues.contains(caseValue)) {
            await _evaluateBody(node.body, evaluator, buffer);
            matchFound = true;
          }
        } else if (node.name == 'else') {
          elseTag = node;
        }
      }
    }

    if (!matchFound && elseTag != null) {
      await _evaluateBody(elseTag.body, evaluator, buffer);
    }
  }

  Future<void> _evaluateBody(
      List<ASTNode> nodeBody, Evaluator evaluator, Buffer buffer) async {
    for (final subNode in nodeBody) {
      if (subNode is Tag) {
        await evaluator.evaluate(subNode);
      } else {
        buffer.write(await evaluator.evaluate(subNode));
      }
    }
  }
}
