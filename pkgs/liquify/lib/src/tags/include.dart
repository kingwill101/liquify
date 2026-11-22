import 'package:liquify/src/tag.dart';

class IncludeTag extends AbstractTag with AsyncTag {
  IncludeTag(super.content, super.filters);

  @override
  void evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final name = evaluator.evaluate(content.first) as String;
    final nodes = evaluator.resolveAndParseTemplate(name);
    final variables = {
      for (final arg in namedArgs)
        arg.identifier.name: evaluator.evaluate(arg.value),
    };
    evaluator.context.pushScope();
    try {
      evaluator.context.merge(variables);
      evaluator.evaluateNodes(nodes);
    } finally {
      evaluator.context.popScope();
    }
  }

  @override
  Future<void> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final name = await evaluator.evaluateAsync(content.first) as String;
    final nodes = await evaluator.resolveAndParseTemplateAsync(name);
    final variables = {
      for (final arg in namedArgs)
        arg.identifier.name: await evaluator.evaluateAsync(arg.value),
    };
    evaluator.context.pushScope();
    try {
      evaluator.context.merge(variables);
      await evaluator.evaluateNodesAsync(nodes);
    } finally {
      evaluator.context.popScope();
    }
  }
}
