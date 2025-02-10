import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tag_registry.dart';

class LiquidTag extends AbstractTag with CustomTagParser, AsyncTag {
  LiquidTag(super.content, super.filters);

  Future<dynamic> _evaluateLiquid(Evaluator evaluator,
      {bool isAsync = false}) async {
    Evaluator innerEvaluator = evaluator.createInnerEvaluator()
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
    return _evaluateLiquid(evaluator, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    return _evaluateLiquid(evaluator, isAsync: true);
  }

  @override
  Parser parser() => (tagStart() &
              string('liquid').trim() &
              any().starLazy(tagEnd()).flatten() &
              tagEnd())
          .map((values) {
        return Tag("liquid", liquidTagContents(values[2], TagRegistry.tags));
      });

  List<ASTNode> liquidTagContents(String content, List<String> tagRegistry) {
    final lines = content.split('\n').map((line) => line.trim()).toList();
    StringBuffer buffer = StringBuffer();
    for (var line in lines) {
      final firstWord = line.split(' ').first;

      if (tagRegistry.contains(firstWord)) {
        buffer.writeln("{% $line %}");
      } else {
        buffer.writeln(line);
      }
    }

    return parseInput(buffer.toString());
  }
}
