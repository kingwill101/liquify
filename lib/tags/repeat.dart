import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/tag.dart';

class RepeatTag extends BaseTag {
  RepeatTag(super.content, super.filters);

  @override
  bool get hasEndTag => true;

  @override
  dynamic evaluate(Evaluator evaluator, StringBuffer buffer) {
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

  @override
  evaluateWithContext(Evaluator evaluator, StringBuffer buffer) {
    // TODO: implement evaluateWithContext
    throw UnimplementedError();
  }
}
