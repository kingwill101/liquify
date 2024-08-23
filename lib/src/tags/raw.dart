import 'package:liquify/src/tag.dart';

class RawTag extends AbstractTag with CustomTagParser {
  RawTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    for (final node in content) {
      if (node is TextNode) {
        buffer.write(evaluator.evaluate(node));
      }
    }
  }

  @override
  Parser parser() {
    return (tagStart() &
            string('raw').trim() &
            tagEnd() &
            any()
                .starLazy((tagStart() & string('endraw').trim() & tagEnd()))
                .flatten() &
            tagStart() &
            string('endraw').trim() &
            tagEnd())
        .map((values) {
      return Tag("raw", [TextNode(values[3])]);
    });
  }
}
