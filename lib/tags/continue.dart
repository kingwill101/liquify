import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/exceptions.dart';
import 'package:liquid_grammar/tag.dart';

class ContinueTag extends BaseTag {
  ContinueTag(super.content, super.filters);

  @override
  bool get hasEndTag => false;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, StringBuffer buffer) {
    throw ContinueException();
  }
}
