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
    final bindings = <String, dynamic>{};
    final bindingName = arguments.bindingName(name);
    evaluator.context.pushScope();
    try {
      for (final arg in namedArgs) {
        final key = arg.identifier.name;
        final argumentValue = evaluator.evaluate(arg.value);
        bindings[key] = argumentValue;
        evaluator.context.setVariable(key, argumentValue);
      }
      for (final item in value is List ? value : [value]) {
        bindings[bindingName] = item;
        evaluator.context.setVariable(bindingName, item);
        evaluator.evaluateBody(nodes);
      }
    } finally {
      _leavePartial(evaluator, bindings);
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
    final bindings = <String, dynamic>{};
    final bindingName = arguments.bindingName(name);
    evaluator.context.pushScope();
    try {
      for (final arg in namedArgs) {
        final key = arg.identifier.name;
        final argumentValue = await evaluator.evaluateAsync(arg.value);
        bindings[key] = argumentValue;
        evaluator.context.setVariable(key, argumentValue);
      }
      for (final item in value is List ? value : [value]) {
        bindings[bindingName] = item;
        evaluator.context.setVariable(bindingName, item);
        await evaluator.evaluateBodyAsync(nodes);
      }
    } finally {
      _leavePartial(evaluator, bindings);
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
