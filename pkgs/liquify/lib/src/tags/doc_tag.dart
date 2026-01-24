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
  Parser parser([LiquidConfig? config]) {
    final start = createTagStart(config);
    final end = createTagEnd(config);
    return (start &
            string('doc').trim() &
            end &
            any().starLazy((start & string('enddoc').trim() & end)).flatten() &
            start &
            string('enddoc').trim() &
            end)
        .map((values) {
          return Tag("doc", [TextNode(values[3])]);
        });
  }
}
