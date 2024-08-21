import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/tag.dart';

class EchoTag extends BaseTag {
  EchoTag(super.content, super.filters);

  @override
  bool get hasEndTag => false;

  @override
   evaluate(Evaluator evaluator, StringBuffer buffer) {
    super.evaluate(evaluator, buffer);
    var value = evaluateContent(evaluator);
    buffer.write(applyFilters(value, evaluator));
  }
  
  @override
  evaluateWithContext(Evaluator evaluator, StringBuffer buffer) {
    // TODO: implement evaluateWithContext
    throw UnimplementedError();
  }
}
