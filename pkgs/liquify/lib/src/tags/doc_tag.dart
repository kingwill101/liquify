import 'package:liquify/src/tag.dart';

class DocTag extends AbstractTag with CustomTagParser, AsyncTag {
  DocTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {}

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {}

  @override
  Parser parser() {
    return (tagStart() &
            string('doc').trim() &
            tagEnd() &
            any()
                .starLazy((tagStart() & string('enddoc').trim() & tagEnd()))
                .flatten() &
            tagStart() &
            string('enddoc').trim() &
            tagEnd())
        .map((values) {
          return Tag("doc", [TextNode(values[3])]);
        });
  }
}
