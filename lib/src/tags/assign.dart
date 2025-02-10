import 'dart:async';

import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class AssignTag extends AbstractTag with AsyncTag {
  AssignTag(super.content, super.filters);

  Assignment? get assignment => content.whereType<Assignment>().firstOrNull;

  assignmentIsVariable() => assignment?.variable is Identifier;

  Identifier get variable => assignment?.variable as Identifier;

  Future<dynamic> _evaluateAssignment(Evaluator evaluator,
      {bool isAsync = false}) async {
    if (assignmentIsVariable()) {
      final value = isAsync
          ? await evaluator.evaluateAsync(assignment!.value)
          : evaluator.evaluate(assignment!.value);
      _setVar(evaluator, value);
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    return _evaluateAssignment(evaluator, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    return _evaluateAssignment(evaluator, isAsync: true);
  }

  _setVar(Evaluator e, dynamic value) {
    e.context.setVariable(variable.name, value);
  }
}
