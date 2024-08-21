import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/exceptions.dart';
import 'package:liquid_grammar/tag.dart';

class IfTag extends BaseTag {
  bool conditionMet = false;

  IfTag(super.content, super.filters);

  @override
  bool get hasEndTag => true;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, StringBuffer buffer) {
    List<ASTNode> currentBody = [];
    List<ASTNode> elseBody = [];
    bool inElseBlock = false;

    // Subdivide the body into elseif and else blocks
    for (int i = 0; i < body.length; i++) {
      final node = body[i];

      if (node is Tag) {
        if (node.name == 'elseif' && !inElseBlock) {
          if (!conditionMet) {
            final elseifCondition = evaluator.evaluate(node.content[0]);
            if (elseifCondition) {
              conditionMet = true;
              currentBody = _extractSubBlock(body, i + 1);
            }
          }
        } else if (node.name == 'else' && !inElseBlock) {
          inElseBlock = true;
          if (!conditionMet) {
            conditionMet = true;
            elseBody = _extractSubBlock(body, i + 1);
          }
        }
      }
    }

    // Evaluate the current body if a condition was met
    if (conditionMet) {
      for (final subNode in currentBody) {
        try {
          buffer.write(evaluator.evaluate(subNode));
        } on BreakException {
          throw BreakException();
        } on ContinueException {
          throw ContinueException();
        }
      }
    } else {
      // Evaluate the else body if no condition was met
      for (final subNode in elseBody) {
        try {
          buffer.write(evaluator.evaluate(subNode));
        } on BreakException {
          throw BreakException();
        } on ContinueException {
          throw ContinueException();
        }
      }
    }

    return buffer.toString();
  }

  List<ASTNode> _extractSubBlock(List<ASTNode> nodes, int startIndex) {
    List<ASTNode> subBlock = [];
    int nestedCount = 0;

    for (int i = startIndex; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is Tag) {
        if (node.name == 'if' || node.name == 'elseif' || node.name == 'else') {
          if (nestedCount == 0) {
            break;
          }
          nestedCount--;
        } else if (node.name.startsWith('end')) {
          nestedCount++;
        }
      }
      subBlock.add(node);
    }
    return subBlock;
  }
}