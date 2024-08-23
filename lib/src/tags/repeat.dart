import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class RepeatTag extends AbstractTag {
  RepeatTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    super.evaluate(evaluator, buffer);

    final times = int.parse(evaluator.evaluate(content.first));
    final repeatedContent = content.skip(1).toList();
    var value = List.generate(
        times,
        (_) => repeatedContent
            .map((node) => evaluator.evaluate(node))
            .join(' ')).join(' ');
    buffer.write(applyFilters(value, evaluator));
  }
}
