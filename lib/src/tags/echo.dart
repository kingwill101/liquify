import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/buffer.dart';

class EchoTag extends AbstractTag {
  EchoTag(super.content, super.filters);

  @override
  Future<dynamic> evaluate(
      Evaluator evaluator, Buffer buffer) async {
    final value = await evaluateContent(evaluator);
    final filtered = await applyFilters(value, evaluator);
    if (filtered != null) {
      buffer.write(filtered);
    }
    return null;
  }
}
