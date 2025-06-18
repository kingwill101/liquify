import 'package:liquify/src/tag.dart';

class CommentTag extends AbstractTag with CustomTagParser, AsyncTag {
  CommentTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {}

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {}

  @override
  Parser parser() {
    return (tagStart() &
            string('comment').trim() &
            tagEnd() &
            any()
                .starLazy((tagStart() & string('endcomment').trim() & tagEnd()))
                .flatten() &
            tagStart() &
            string('endcomment').trim() &
            tagEnd())
        .map((values) {
      return Tag("comment", [TextNode(values[3])]);
    });
  }
}
