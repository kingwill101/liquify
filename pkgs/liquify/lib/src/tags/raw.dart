import 'package:liquify/src/tag.dart';

class RawTag extends AbstractTag with CustomTagParser, AsyncTag {
  RawTag(super.content, super.filters);

  Future<dynamic> _evaluateRaw(
    Evaluator evaluator,
    Buffer buffer, {
    bool isAsync = false,
  }) async {
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
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    return _evaluateRaw(evaluator, buffer, isAsync: true);
  }

  @override
  Parser parser([LiquidConfig? config]) {
    final start = createTagStart(config);
    final end = createTagEnd(config);
    return (start &
            string('raw').trim() &
            end &
            any().starLazy((start & string('endraw').trim() & end)).flatten() &
            start &
            string('endraw').trim() &
            end)
        .map((values) {
          return Tag("raw", [TextNode(values[3])]);
        });
  }
}
