import 'package:liquid_grammar/ast.dart';

import 'evaluator.dart';

abstract class BaseTag {
  final List<ASTNode> content;
  final List<Filter> filters;
  List<ASTNode> body = [];

  BaseTag(this.content, this.filters, [this.body = const []]);

  List<NamedArgument> get namedArgs =>
      content.whereType<NamedArgument>().toList();

  List<Identifier> get args => content.whereType<Identifier>().toList();

  bool get hasEndTag;

  bool get hasLimit => namedArgs.any((arg) => arg.name.name == 'limit');

  bool get hasOffset => namedArgs.any((arg) => arg.name.name == 'offset');

  bool hasReverse() => content.any((arg) => content
      .whereType<Identifier>()
      .where((i) => i.name == "reversed")
      .isNotEmpty);

  void preprocess(Evaluator evaluator) {
    // Default implementation does nothing
  }

  dynamic evaluateContent(Evaluator evaluator) {
    return content.map((node) => evaluator.evaluate(node)).join('');
  }

  dynamic applyFilters(dynamic value, Evaluator evaluator) {
    for (final filter in filters) {
      final filterFunction = evaluator.context.getFilter(filter.name.name);
      if (filterFunction == null) {
        throw Exception('Undefined filter: ${filter.name.name}');
      }
      final args =
          filter.arguments.map((arg) => evaluator.evaluate(arg)).toList();
      value = filterFunction(value, args, {});
    }
    return value;
  }

  dynamic evaluate(Evaluator evaluator, StringBuffer buffer) {
    evaluator.context.pushScope();
    final result =
        evaluateWithContext(evaluator.createInnerEvaluator(), buffer);
    evaluator.context.popScope();
    return result;
  }

  dynamic evaluateWithContext(Evaluator evaluator, StringBuffer buffer);
}
