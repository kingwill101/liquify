import 'dart:async';

import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/tags/tag.dart';

class AssignTag extends AbstractTag with AsyncTag {
  AssignTag(super.content, super.filters);

  Assignment? get assignment => content.whereType<Assignment>().firstOrNull;

  bool assignmentIsVariable() => assignment?.variable is Identifier;

  Identifier get variable => assignment?.variable as Identifier;

  FilteredExpression? get filteredAssignment {
    for (final expr in content.whereType<FilteredExpression>()) {
      if (expr.expression is Assignment) {
        return expr;
      }
    }
    return null;
  }

  Future<dynamic> _evaluateAssignment(
    Evaluator evaluator, {
    bool isAsync = false,
  }) async {
    if (assignmentIsVariable()) {
      final value = isAsync
          ? await evaluator.evaluateAsync(assignment!.value)
          : evaluator.evaluate(assignment!.value);
      evaluator.context.setVariable(variable.name, value);
      return null;
    }
    final filtered = filteredAssignment;
    if (filtered != null) {
      final assignmentExpr = filtered.expression as Assignment;
      if (assignmentExpr.variable is Identifier) {
        final filteredValue = isAsync
            ? await evaluator.evaluateAsync(filtered)
            : evaluator.evaluate(filtered);
        evaluator.context.setVariable(
          (assignmentExpr.variable as Identifier).name,
          filteredValue,
        );
      }
    }
    return null;
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    return _evaluateAssignment(evaluator, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    return _evaluateAssignment(evaluator, isAsync: true);
  }
}
