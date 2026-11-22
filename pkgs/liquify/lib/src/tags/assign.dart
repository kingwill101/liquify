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

  (Identifier, ASTNode)? _assignmentTarget() {
    final direct = assignment;
    if (direct case Assignment(
      variable: final Identifier target,
      :final value,
    )) {
      return (target, value);
    }

    final filtered = filteredAssignment;
    if (filtered case FilteredExpression(
      expression: Assignment(variable: final Identifier target),
    )) {
      return (target, filtered);
    }
    return null;
  }

  @override
  void evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (_assignmentTarget() case (final target, final expression)) {
      final value = evaluator.evaluate(expression);
      evaluator.context.setVariable(target.name, value);
    }
  }

  @override
  Future<void> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    if (_assignmentTarget() case (final target, final expression)) {
      final value = await evaluator.evaluateAsync(expression);
      evaluator.context.setVariable(target.name, value);
    }
  }
}
