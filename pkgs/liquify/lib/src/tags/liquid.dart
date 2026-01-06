import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tag_registry.dart';

class LiquidTag extends AbstractTag with CustomTagParser, AsyncTag {
  LiquidTag(super.content, super.filters);

  Future<dynamic> _evaluateLiquid(
    Evaluator evaluator,
    Buffer buffer, {
    bool isAsync = false,
  }) async {
    Evaluator innerEvaluator = evaluator.createInnerEvaluatorWithBuffer(buffer)
      ..context.setRoot(evaluator.context.getRoot());

    if (isAsync) {
      await innerEvaluator.evaluateNodesAsync(content);
    } else {
      innerEvaluator.evaluateNodes(content);
    }

    evaluator.context.merge(innerEvaluator.context.all());
    return null;
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    return _evaluateLiquid(evaluator, buffer, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    return _evaluateLiquid(evaluator, buffer, isAsync: true);
  }

  @override
  Parser parser() =>
      (tagStart() &
              string('liquid').trim() &
              any().starLazy(tagEnd()).flatten() &
              tagEnd())
          .map((values) {
            return Tag(
              "liquid",
              liquidTagContents(values[2], TagRegistry.tags),
            );
          });

  List<ASTNode> liquidTagContents(String content, List<String> tagRegistry) {
    if (content.contains('\r') && !content.contains('\n')) {
      throw Exception('Liquid tag does not support CR-only line endings.');
    }
    final lines = content.split('\n');
    StringBuffer buffer = StringBuffer();
    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        continue;
      }
      if (trimmedLine.startsWith('{#') || trimmedLine.startsWith('#')) {
        continue;
      }
      if (trimmedLine.startsWith('{%') || trimmedLine.startsWith('{{')) {
        buffer.write(trimmedLine);
        continue;
      }
      buffer.write("{% $trimmedLine %}");
    }

    return parseInput(buffer.toString());
  }
}
