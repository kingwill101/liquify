import 'package:liquify/parser.dart';
import 'package:liquify/src/context.dart';

/// The Template class provides static methods for parsing and rendering Liquid templates.
class Template {
  /// Parses and evaluates a Liquid template string.
  ///
  /// [input] is the Liquid template string to be parsed and evaluated.
  /// [data] is an optional map of variables to be used in the template evaluation.
  ///
  /// Returns the rendered output as a String.
  static String parse(String input, {Map<String, dynamic> data = const {}}) {
    registerBuiltIns();
    final parsed = parseInput(input);
    Evaluator evaluator = Evaluator(Environment(data));
    evaluator.evaluateNodes(parsed);
    return evaluator.buffer.toString();
  }
}
