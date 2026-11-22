import 'package:liquify/src/tag.dart';

class CaptureTag extends AbstractTag with CustomTagParser, AsyncTag {
  late String variableName;

  CaptureTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! Identifier) {
      throw Exception(
        'CaptureTag requires a variable name as the first argument.',
      );
    }
    variableName = (content.first as Identifier).name;
  }

  @override
  void evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
    } finally {
      final captured = evaluator.endBlockCapture();
      evaluator.context.setVariable(variableName, captured);
    }
  }

  @override
  Future<void> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
    } finally {
      final captured = evaluator.endBlockCapture();
      evaluator.context.setVariable(variableName, captured);
    }
  }

  @override
  Parser parser([LiquidConfig? config]) {
    final close = someTag('endcapture', config: config, hasContent: false);
    final open = someTag('capture', config: config);
    final nested = undefined();
    final body = (nested | (open | close).not() & any()).star().flatten();
    nested.set(open & body & close);
    return (open & body & close).map((values) {
      final tag = values[0] as Tag;
      tag.body = parseInput(values[1] as String, config: config);
      return tag;
    });
  }
}
