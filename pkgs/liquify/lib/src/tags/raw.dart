import 'package:liquify/src/tag.dart';

class RawTag extends AbstractTag with CustomTagParser, AsyncTag {
  RawTag(super.content, super.filters);

  Future<dynamic> _evaluateRaw(Evaluator evaluator, Buffer buffer,
      {bool isAsync = false}) async {
    for (final node in content) {
      if (node is TextNode) {
        final value = isAsync
            ? await evaluator.evaluateAsync(node)
            : evaluator.evaluate(node);
        buffer.write(value);
      }
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    return _evaluateRaw(evaluator, buffer, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    return _evaluateRaw(evaluator, buffer, isAsync: true);
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
