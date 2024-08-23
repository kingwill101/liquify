import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/buffer.dart';

class EchoTag extends AbstractTag {
  EchoTag(super.content, super.filters);

  @override
  evaluate(Evaluator evaluator, Buffer buffer) {
    super.evaluate(evaluator, buffer);
    var value = evaluateContent(evaluator);
    buffer.write(applyFilters(value, evaluator));
  }
}
