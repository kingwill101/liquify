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
  void preprocess(Evaluator evaluator) {
    // Default implementation does nothing
  }

  /// Evaluates the tag's content and returns the result as a string.
  dynamic evaluateContent(Evaluator evaluator) {
    return content.map((node) => evaluator.evaluate(node)).join('');
  }

  /// Evaluates the tag's content asynchronously and returns the result as a string.
  Future<dynamic> evaluateContentAsync(Evaluator evaluator) async {
    final results =
        await Future.wait(content.map((node) => evaluator.evaluateAsync(node)));
    return results.join('');
  }

  /// Applies the tag's filters to the given value.
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

  /// Applies the tag's filters to the given value asynchronously.
  Future<dynamic> applyFiltersAsync(dynamic value, Evaluator evaluator) async {
    for (final filter in filters) {
      final filterFunction = evaluator.context.getFilter(filter.name.name);
      if (filterFunction == null) {
        throw Exception('Undefined filter: ${filter.name.name}');
      }
      final args = await Future.wait(
          filter.arguments.map((arg) => evaluator.evaluateAsync(arg)));
      value = filterFunction(value, args, {});
    }
    return value;
  }

  /// Evaluates the tag, pushing a new scope before evaluation and popping it after.
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    evaluator.context.pushScope();
    final result = evaluateWithContext(
        evaluator.createInnerEvaluator()
          ..context.setRoot(evaluator.context.getRoot()),
        buffer);
    evaluator.context.popScope();
    return result;
  }

  /// Evaluates the tag asynchronously, pushing a new scope before evaluation and popping it after.
  Future<dynamic> evaluateAsync(Evaluator evaluator, Buffer buffer) async {
    evaluator.context.pushScope();
    final result = await evaluateWithContextAsync(
        evaluator.createInnerEvaluator()
          ..context.setRoot(evaluator.context.getRoot()),
        buffer);
    evaluator.context.popScope();
    return result;
  }

  /// Evaluates the tag within the given context. Override this method in subclasses.
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {}

  /// Evaluates the tag within the given context asynchronously. Override this method in subclasses.
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {}
}
