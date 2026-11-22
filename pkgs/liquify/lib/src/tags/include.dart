import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tags/partial_arguments.dart';

class IncludeTag extends AbstractTag with AsyncTag {
  IncludeTag(super.content, super.filters);

  PartialArguments get _arguments => PartialArguments(
    content.skip(1).where((node) => node is! NamedArgument).toList(),
  );

  @override
  void evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final name = evaluator.evaluate(content.first) as String;
    final nodes = evaluator.resolveAndParseTemplate(name);
    final arguments = _arguments;
    final binding = arguments.binding;
    final value = binding == null
        ? evaluator.context.getVariable(name)
        : evaluator.evaluate(binding);
    final assignments = <String, dynamic>{};
    final bindingName = arguments.bindingName(name);
    final argumentsToBind = namedArgs;
    final localNames = {
      bindingName,
      for (final arg in argumentsToBind) arg.identifier.name,
    };
    evaluator.context.pushScope();
    try {
      for (final arg in argumentsToBind) {
        final key = arg.identifier.name;
        final argumentValue = evaluator.evaluate(arg.value);
        evaluator.context.setVariable(key, argumentValue);
      }
      for (final item in value is List ? value : [value]) {
        evaluator.context.setVariable(bindingName, item);
        evaluator.context.pushScope();
        try {
          evaluator.evaluateBody(nodes);
        } finally {
          _collectAssignments(evaluator, assignments, localNames);
        }
      }
    } finally {
      evaluator.context.popScope();
      evaluator.context.merge(assignments);
    }
  }

  @override
  Future<void> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final name = await evaluator.evaluateAsync(content.first) as String;
    final nodes = await evaluator.resolveAndParseTemplateAsync(name);
    final arguments = _arguments;
    final binding = arguments.binding;
    final value = binding == null
        ? evaluator.context.getVariable(name)
        : await evaluator.evaluateAsync(binding);
    final assignments = <String, dynamic>{};
    final bindingName = arguments.bindingName(name);
    final argumentsToBind = namedArgs;
    final localNames = {
      bindingName,
      for (final arg in argumentsToBind) arg.identifier.name,
    };
    evaluator.context.pushScope();
    try {
      for (final arg in argumentsToBind) {
        final key = arg.identifier.name;
        final argumentValue = await evaluator.evaluateAsync(arg.value);
        evaluator.context.setVariable(key, argumentValue);
      }
      for (final item in value is List ? value : [value]) {
        evaluator.context.setVariable(bindingName, item);
        evaluator.context.pushScope();
        try {
          await evaluator.evaluateBodyAsync(nodes);
        } finally {
          _collectAssignments(evaluator, assignments, localNames);
        }
      }
    } finally {
      evaluator.context.popScope();
      evaluator.context.merge(assignments);
    }
  }

  void _collectAssignments(
    Evaluator evaluator,
    Map<String, dynamic> assignments,
    Set<String> localNames,
  ) {
    final written = evaluator.context.currentScopeVariables();
    evaluator.context.popScope();
    assignments.addAll(written);

    // Later iterations can read previous assignments. Temporary arguments
    // retain precedence inside this include and are discarded on exit.
    written.removeWhere((name, _) => localNames.contains(name));
    evaluator.context.merge(written);
  }
}
