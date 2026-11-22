import 'package:liquify/src/context.dart';
import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tags/for.dart';
import 'package:liquify/src/tags/partial_arguments.dart';

class RenderTag extends AbstractTag with AsyncTag {
  late String templateName;
  late PartialArguments _arguments;

  RenderTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    final name = content.firstOrNull;
    if (name is! Literal || name.type != LiteralType.string) {
      throw ArgumentError('Render template name must be a quoted string');
    }
    templateName = name.value as String;
    _arguments = PartialArguments(
      content.skip(1).where((node) => node is! NamedArgument).toList(),
    );
  }

  Iterable<Map<String, dynamic>> _iterations(
    Object? binding,
    Map<String, dynamic> variables,
  ) sync* {
    final bindingName = _arguments.bindingName(templateName);
    if (!_arguments.iterate || (binding is! List && binding is! Map)) {
      yield {...variables, bindingName: ?binding};
      return;
    }

    final items = sliceLoopItems(binding, 0, null);
    final loop = ForLoopObject(name: templateName, length: items.length);
    for (final item in items) {
      yield {...variables, 'forloop': loop.toMap(), bindingName: ?item};
      loop.increment();
    }
  }

  Evaluator _partialEvaluator(
    Evaluator parent,
    Buffer buffer,
    Map<String, dynamic> variables,
  ) {
    final context = Environment(variables)
      ..setRoot(parent.context.getRoot())
      ..setConfig(parent.context.config);
    return Evaluator.withBuffer(context, buffer);
  }

  @override
  void evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final nodes = evaluator.resolveAndParseTemplate(templateName);
    final binding = _arguments.binding;
    final value = binding == null ? null : evaluator.evaluate(binding);
    final variables = {
      for (final arg in namedArgs)
        arg.identifier.name: evaluator.evaluate(arg.value),
    };
    for (final scope in _iterations(value, variables)) {
      _partialEvaluator(evaluator, buffer, scope).evaluateNodes(nodes);
    }
  }

  @override
  Future<void> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final nodes = await evaluator.resolveAndParseTemplateAsync(templateName);
    final binding = _arguments.binding;
    final value = binding == null
        ? null
        : await evaluator.evaluateAsync(binding);
    final variables = {
      for (final arg in namedArgs)
        arg.identifier.name: await evaluator.evaluateAsync(arg.value),
    };
    for (final scope in _iterations(value, variables)) {
      await _partialEvaluator(
        evaluator,
        buffer,
        scope,
      ).evaluateNodesAsync(nodes);
    }
  }
}
