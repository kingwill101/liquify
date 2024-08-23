import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class AssignTag extends AbstractTag {
  AssignTag(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final assignment = content.whereType<Assignment>().firstOrNull;
    if (assignment == null) {
      return;
    }
    evaluator.evaluate(assignment);
  }
}
