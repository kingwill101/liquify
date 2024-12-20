import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';

import '../evaluator.dart';

/// Abstract base class for all Liquid tags.
abstract class AbstractTag {
  /// The content nodes of the tag.
  final List<ASTNode> content;

  /// The filters applied to the tag's output.
  final List<Filter> filters;

  /// The body nodes of the tag (for block tags).
  List<ASTNode> body = [];

  /// Constructs a new BaseTag with the given content, filters, and optional body.
  AbstractTag(this.content, this.filters, [this.body = const []]);

  /// Returns a list of all named arguments in the tag's content.
  List<NamedArgument> get namedArgs =>
      content.whereType<NamedArgument>().toList();

  /// Returns a list of all identifiers in the tag's content.
  List<Identifier> get args => content.whereType<Identifier>().toList();

  /// Preprocesses the tag's content. Override this method for custom preprocessing.
  Future<void> preprocess(Evaluator evaluator) async {}

  /// Evaluates the tag's content and returns the result as a string.
  Future<String> evaluateContent(Evaluator evaluator) async {
    return content.map((node) async => await evaluator.evaluate(node)).join('');
  }

  /// Applies the tag's filters to the given value.

  Future<dynamic> applyFilters(dynamic value, Evaluator evaluator) async {
    for (final filter in filters) {
      final filterFunction = evaluator.context.getFilter(filter.name.name);
      if (filterFunction == null) {
        throw Exception('Undefined filter: ${filter.name.name}');
      }
      var args = [];

      filter.arguments.map((arg) async => await evaluator.evaluate(arg));
      value = await filterFunction(value, args, {});
    }
    return value;
  }

  /// Evaluates the tag, pushing a new scope before evaluation and popping it after.
  Future<dynamic> evaluate(Evaluator evaluator, Buffer buffer) async {
    evaluator.context.pushScope();
    final result = await evaluateWithContext(
        evaluator.createInnerEvaluator()
          ..context.setRoot(evaluator.context.getRoot()),
        buffer);
    evaluator.context.popScope();
    return result;
  }

  /// Evaluates the tag within the given context. Override this method in subclasses.
  Future<dynamic> evaluateWithContext(
      Evaluator evaluator, Buffer buffer) async {}
}
