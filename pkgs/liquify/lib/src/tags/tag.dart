import 'dart:async';

import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';

import '../evaluator.dart';

typedef TagCreator = Function(List<ASTNode>, List<Filter>);

/// Marker mixin for tags that support async operations
mixin AsyncTag {
  bool get isAsync => true;
}

/// Abstract base class for all Liquid tags.
///
/// Subclass this to create custom tags. Override [evaluateWithContext] for
/// synchronous evaluation or [evaluateWithContextAsync] for async evaluation.
///
/// ## Accessing Template Configuration
///
/// If your tag needs to re-parse content with the same delimiters as the parent
/// template, access the config from the evaluator's context:
///
/// ```dart
/// @override
/// dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
///   final config = evaluator.context.config;
///   final liquid = Liquid(config: config ?? LiquidConfig.standard);
///   final result = liquid.renderString(content, evaluator.context.all());
///   buffer.write(result);
/// }
/// ```
///
/// See [Environment.config] for more details.
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
    if (content.isEmpty) {
      return '';
    }
    if (content.length == 1) {
      return evaluator.evaluate(content.first);
    }
    return content.map((node) => evaluator.evaluate(node)).join('');
  }

  dynamic evaluateContentAsync(Evaluator eval) {
    if (content.isEmpty) {
      return '';
    }
    if (content.length == 1) {
      return eval.evaluateAsync(content.first);
    }
    return Future.wait(
      content.map((node) => eval.evaluateAsync(node)),
    ).then((results) => results.join(''));
  }

  /// Applies the tag's filters to the given value.
  dynamic applyFilters(dynamic value, Evaluator evaluator) {
    var result = value;
    for (final filter in filters) {
      final filterFunction = evaluator.context.getFilter(filter.name.name);
      if (filterFunction == null) {
        throw Exception('Undefined filter: ${filter.name.name}');
      }
      final args = filter.arguments
          .map((arg) => evaluator.evaluate(arg))
          .toList();
      result = filterFunction(result, args, {});
    }
    return result;
  }

  Future<dynamic> applyFiltersAsync(dynamic value, Evaluator evaluator) async {
    for (final filter in filters) {
      final filterFunction = evaluator.context.getFilter(filter.name.name);
      if (filterFunction == null) {
        throw Exception('Undefined filter: ${filter.name.name}');
      }
      final args = await Future.wait(
        filter.arguments.map((arg) => evaluator.evaluateAsync(arg)),
      );
      value = filterFunction(value, args, {});
    }
    return value;
  }

  /// Evaluates the tag with proper scope management
  FutureOr<dynamic> evaluateAsync(Evaluator evaluator, Buffer buffer) async {
    evaluator.context.pushScope();

    final innerContext = evaluator.context.clone();
    final innerEvaluator = Evaluator.withBuffer(innerContext, buffer)
      ..context.setRoot(evaluator.context.getRoot());

    var result = await evaluateWithContextAsync(innerEvaluator, buffer);

    // Store the variables from the current scope before popping it
    final currentScopeVariables = innerEvaluator.context.all();
    evaluator.context.popScope();

    // Merge the stored variables back into the previous scope
    evaluator.context.merge(currentScopeVariables);

    return result;
  }

  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    evaluator.context.pushScope();

    final innerContext = evaluator.context.clone();
    final innerEvaluator = Evaluator.withBuffer(innerContext, buffer)
      ..context.setRoot(evaluator.context.getRoot());

    var result = evaluateWithContext(innerEvaluator, buffer);

    // Store the variables from the current scope before popping it
    final currentScopeVariables = innerEvaluator.context.all();
    evaluator.context.popScope();

    // Merge the stored variables back into the previous scope
    evaluator.context.merge(currentScopeVariables);

    return result;
  }

  /// Override this method in subclasses to implement tag behavior
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {}
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {}
}
