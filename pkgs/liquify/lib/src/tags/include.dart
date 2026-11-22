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
    final variables = {
      for (final arg in namedArgs)
        arg.identifier.name: evaluator.evaluate(arg.value),
    };

    for (final item in value is List ? value : [value]) {
      final bindings = {...variables, arguments.bindingName(name): item};
      evaluator.context.pushScope();
      try {
        evaluator.context.merge(bindings);
        evaluator.evaluateNodes(nodes);
      } finally {
        _leavePartial(evaluator, bindings);
      }
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
    final variables = {
      for (final arg in namedArgs)
        arg.identifier.name: await evaluator.evaluateAsync(arg.value),
    };

    for (final item in value is List ? value : [value]) {
      final bindings = {...variables, arguments.bindingName(name): item};
      evaluator.context.pushScope();
      try {
        evaluator.context.merge(bindings);
        await evaluator.evaluateNodesAsync(nodes);
      } finally {
        _leavePartial(evaluator, bindings);
      }
    }
  }

  void _leavePartial(Evaluator evaluator, Map<String, dynamic> bindings) {
    final values = evaluator.context.all();
    evaluator.context.popScope();

    // Bindings are local, while assignments from the included template persist.
    for (final entry in bindings.entries) {
      if (identical(values[entry.key], entry.value)) values.remove(entry.key);
    }
    evaluator.context.merge(values);
  }
}
