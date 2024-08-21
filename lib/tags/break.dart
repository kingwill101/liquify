
import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/exceptions.dart';
import 'package:liquid_grammar/tag.dart';

class BreakTag extends BaseTag {
  BreakTag(super.content, super.filters);

  @override
  bool get hasEndTag => false;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, StringBuffer buffer) {
    throw BreakException();
  }
}