import 'package:liquify/src/tag.dart';
import 'package:liquify/src/util.dart';

class UnlessTag extends AbstractTag with CustomTagParser {
  bool conditionMet = false;

  UnlessTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    conditionMet = isTruthy(evaluator.evaluate(content[0]));
    if (!conditionMet) {
      for (final subNode in body) {
        if (subNode is Tag) {
          evaluator.evaluate(subNode);
        } else {
          buffer.write(evaluator.evaluate(subNode));
        }
      }
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
