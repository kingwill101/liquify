import 'package:liquify/src/registry.dart';
import 'package:liquify/src/tag.dart';

class LiquidTag extends AbstractTag with CustomTagParser {
  LiquidTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    evaluator.evaluateNodes(content);
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

    return parseInput(
        buffer.toString()); // Return a list or a specific node type
  }
}
