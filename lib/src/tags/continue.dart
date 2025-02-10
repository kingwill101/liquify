import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/buffer.dart';

class ContinueTag extends AbstractTag with AsyncTag {
  ContinueTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    throw ContinueException();
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    throw ContinueException();
  }
}
