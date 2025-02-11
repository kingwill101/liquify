import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class EchoTag extends AbstractTag with AsyncTag {
  EchoTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    var value = evaluateContent(evaluator);
    var filtered = applyFilters(value, evaluator);
    buffer.write(filtered);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    var value = await evaluateContentAsync(evaluator);
    var filtered = await applyFiltersAsync(value, evaluator);
    buffer.write(filtered);
  }
}
