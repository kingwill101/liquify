import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tag.dart';
import 'package:liquify/src/util.dart';

class UnlessTag extends AbstractTag with CustomTagParser, AsyncTag {
  bool conditionMet = false;

  UnlessTag(super.content, super.filters);

  void _renderBlockSync(
      Evaluator evaluator, Buffer buffer, List<ASTNode> body) {
    for (final subNode in body) {
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

  Future<void> _renderBlockAsync(
      Evaluator evaluator, Buffer buffer, List<ASTNode> body) async {
    for (final subNode in body) {
      try {
        if (subNode is Tag) {
          await evaluator.evaluateAsync(subNode);
        } else {
          buffer.write(await evaluator.evaluateAsync(subNode));
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
    if (!conditionMet) {
      _renderBlockSync(evaluator, buffer, body);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    conditionMet = isTruthy(await evaluator.evaluateAsync(content[0]));
    if (!conditionMet) {
      await _renderBlockAsync(evaluator, buffer, body);
    }
  }

  @override
  Parser parser() {
    return (ref0(unlessTag).trim() &
            any().plusLazy(endUnlessTag()) &
            endUnlessTag())
        .map((values) {
      return (values[0] as Tag)
          .copyWith(body: parseInput((values[1] as List).join('')));
    });
  }
}

Parser unlessTag() => someTag("unless");

Parser endUnlessTag() =>
    (tagStart() & string('endunless').trim() & tagEnd()).map((values) {
      return Tag('endunless', []);
    });
