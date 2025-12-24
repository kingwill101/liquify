import 'package:liquify/src/context.dart';
import 'package:liquify/src/tag.dart';
import 'package:liquify/src/tags/for.dart';

class RenderTag extends AbstractTag with AsyncTag {
  late String templateName;
  late Map<String, dynamic> variables;
  bool hasFor = false;

  RenderTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! Literal) {
      throw Exception(
          'RenderTag requires a template name as the first argument.');
    }

    templateName = (content.first as Literal).value;
    variables = {};

    for (final arg in namedArgs) {
      variables[arg.identifier.name] = evaluator.evaluate(arg.value);
    }

    if (args.length > 1) {
      final withArg = args[0];
      if (withArg.name == 'with') {
        if (args.length < 3) {
          throw Exception('RenderTag with "with" requires an object to pass.');
        }
        final object = evaluator.evaluate(args[1]);
        if (args.length == 4 && args[2].name == 'as') {
          variables[(args[3]).name] = object;
        } else {
          variables.addAll(object as Map<String, dynamic>);
        }
      } else if (withArg.name == 'for') {
        if (args.length < 3) {
          throw Exception(
              'RenderTag with "for" requires an enumerable object.');
        }
        hasFor = true;
      }
    }
  }

  void _renderTemplateSync(String template, Evaluator evaluator, Buffer buffer,
      Map<String, dynamic> localVariables) {
    final templateNodes = evaluator.resolveAndParseTemplate(template);
    var env = Environment();
    final currentRoot = evaluator.context.getRoot();

    if (currentRoot != null) {
      env.setRoot(currentRoot);
    }

    final innerEvaluator = Evaluator(env);
    innerEvaluator.context.pushScope();

    for (final entry in localVariables.entries) {
      innerEvaluator.context.setVariable(entry.key, entry.value);
    }

    innerEvaluator.evaluateNodes(templateNodes);
    buffer.write(innerEvaluator.buffer.toString());
    innerEvaluator.context.popScope();
  }

  Future<void> _renderTemplateAsync(String template, Evaluator evaluator,
      Buffer buffer, Map<String, dynamic> localVariables) async {
    final templateNodes =
        await evaluator.resolveAndParseTemplateAsync(template);
    var env = Environment();
    final currentRoot = evaluator.context.getRoot();

    if (currentRoot != null) {
      env.setRoot(currentRoot);
    }

    final innerEvaluator = Evaluator(env);
    innerEvaluator.context.pushScope();

    for (final entry in localVariables.entries) {
      innerEvaluator.context.setVariable(entry.key, entry.value);
    }

    await innerEvaluator.evaluateNodesAsync(templateNodes);
    buffer.write(innerEvaluator.buffer.toString());
    innerEvaluator.context.popScope();
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (hasFor) {
      if (args.length != 4 || args[2].name != 'as') {
        throw Exception(
            'RenderTag with "for" requires "as" and a variable name.');
      }

      final enumerable = evaluator.evaluate(args[1]);
      for (var i = 0; i < enumerable.length; i++) {
        final localVariables = Map<String, dynamic>.from(variables);
        localVariables['forloop'] =
            ForLoopObject(index: i, length: enumerable.length).toMap();
        localVariables[args[3].name] = enumerable[i];

        _renderTemplateSync(templateName, evaluator, buffer, localVariables);
      }
    } else {
      _renderTemplateSync(templateName, evaluator, buffer, variables);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    if (hasFor) {
      if (args.length != 4 || args[2].name != 'as') {
        throw Exception(
            'RenderTag with "for" requires "as" and a variable name.');
      }

      final enumerable = await evaluator.evaluateAsync(args[1]);
      for (var i = 0; i < enumerable.length; i++) {
        final localVariables = Map<String, dynamic>.from(variables);
        localVariables['forloop'] =
            ForLoopObject(index: i, length: enumerable.length).toMap();
        localVariables[args[3].name] = enumerable[i];

        await _renderTemplateAsync(
            templateName, evaluator, buffer, localVariables);
      }
    } else {
      await _renderTemplateAsync(templateName, evaluator, buffer, variables);
    }
  }
}
