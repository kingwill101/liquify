import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/buffer.dart';

class BreakTag extends AbstractTag {
  BreakTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    throw BreakException();
  }
}