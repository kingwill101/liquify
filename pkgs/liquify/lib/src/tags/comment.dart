import 'package:liquify/src/tag.dart';

class CommentTag extends AbstractTag with CustomTagParser, AsyncTag {
  CommentTag(super.content, super.filters);

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
            string('comment').trim() &
            end &
            any()
                .starLazy((start & string('endcomment').trim() & end))
                .flatten() &
            start &
            string('endcomment').trim() &
            end)
        .map((values) {
          return Tag("comment", [TextNode(values[3])]);
        });
  }
}
