import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class CaseTag extends AbstractTag with AsyncTag {
  late dynamic caseValue;

  CaseTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty) {
      throw Exception('CaseTag requires a value to switch on.');
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

  Future<void> _evaluateBodyAsync(
      List<ASTNode> nodeBody, Evaluator evaluator, Buffer buffer) async {
    for (final subNode in nodeBody) {
      if (subNode is Tag) {
        await evaluator.evaluateAsync(subNode);
      } else {
        buffer.write(await evaluator.evaluateAsync(subNode));
      }
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    caseValue = evaluator.evaluate(content[0]);
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

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    caseValue = await evaluator.evaluateAsync(content[0]);
    Tag? elseTag;
    bool matchFound = false;

    for (final node in body) {
      if (node is Tag) {
        if (node.name == 'when' && !matchFound) {
          final whenValues = await Future.wait(
              node.content.map((e) => evaluator.evaluateAsync(e)));
          if (whenValues.contains(caseValue)) {
            await _evaluateBodyAsync(node.body, evaluator, buffer);
            matchFound = true;
          }
        } else if (node.name == 'else') {
          elseTag = node;
        }
      }
    }

    if (!matchFound && elseTag != null) {
      await _evaluateBodyAsync(elseTag.body, evaluator, buffer);
    }
  }
}
