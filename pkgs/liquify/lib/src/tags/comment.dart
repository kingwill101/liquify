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
    final open = someTag('comment', config: config, hasContent: false);
    final close = someTag('endcomment', config: config, hasContent: false);
    final nested = undefined();
    final body = (nested | (open | close).not() & any()).star().flatten();
    nested.set(open & body & close);
    return (open & body & close).map(
      (values) => Tag('comment', [TextNode(values[1])]),
    );
  }
}
