import 'package:liquify/parser.dart' as parser;
import 'package:liquify/src/context.dart';
import 'package:liquify/src/fs.dart';
import 'package:liquify/src/evaluator.dart';


class Template {
  final String _templateContent;
  final Evaluator _evaluator;

  /// Creates a new Template instance from a file.
  ///
  /// [templateName] is the name or path of the template to be rendered.
  /// [root] is the Root object used for resolving templates.
  /// [data] is an optional map of variables to be used in the template evaluation.
  Template.fromFile(String templateName, Root root, {Map<String, dynamic> data = const {}})
      : _templateContent = root.resolve(templateName).content,
        _evaluator = Evaluator(Environment(data)..setRoot(root));

  /// Creates a new Template instance from a string.
  ///
  /// [input] is the string content of the template.
  /// [data] is an optional map of variables to be used in the template evaluation.
  Template.parse(String input, {Map<String, dynamic> data = const {}, Evaluator? evaluator})
      : _templateContent = input,
        _evaluator = evaluator ?? Evaluator(Environment(data));

  /// Renders the template with the current context.
  ///
  /// Returns the rendered output as a String.
  String render() {
    final parsed = parser.parseInput(_templateContent);
    _evaluator.evaluateNodes(parsed);
    return _evaluator.buffer.toString();
  }

  /// Updates the template context with new data.
  ///
  /// [newData] is a map of variables to be merged into the existing context.
  void updateContext(Map<String, dynamic> newData) {
    _evaluator.context.merge(newData);
  }
}
