import 'package:liquify/src/tag.dart';

class UnlessTag extends AbstractTag with CustomTagParser {
  bool conditionMet = false;

  UnlessTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    conditionMet = evaluator.evaluate(content[0]);
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
      final tag = values[0] as Tag;
      tag.body = parseInput((values[1] as List).join(''));
      return tag;
    });
  }
}

Parser unlessTag() => someTag("unless");

Parser endUnlessTag() =>
    (tagStart() & string('endunless').trim() & tagEnd()).map((values) {
      return Tag('endunless', []);
    });
