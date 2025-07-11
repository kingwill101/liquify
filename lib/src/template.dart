import 'package:liquify/parser.dart' as parser;
import 'package:liquify/parser.dart';
import 'package:liquify/src/fs.dart';

class Template {
  final String _templateContent;
  final Evaluator _evaluator;

  /// Creates a new Template instance from a file.
  ///
  /// [templateName] is the name or path of the template to be rendered.
  /// [root] is the Root object used for resolving templates.
  /// [data] is an optional map of variables to be used in the template evaluation.
  /// [environment] is an optional custom Environment instance to use.
  /// [environmentSetup] is an optional callback to configure the environment with custom filters/tags.
  Template.fromFile(String templateName, Root root,
      {Map<String, dynamic> data = const {},
      Environment? environment,
      void Function(Environment)? environmentSetup})
      : _templateContent = root.resolve(templateName).content,
        _evaluator = Evaluator(
            _createEnvironment(data, environment, environmentSetup)
              ..setRoot(root));

  /// Creates a new Template instance from a string.
  ///
  /// [input] is the string content of the template.
  /// [data] is an optional map of variables to be used in the template evaluation.
  /// [root] is an optional Root object used for resolving templates.
  /// [environment] is an optional custom Environment instance to use.
  /// [environmentSetup] is an optional callback to configure the environment with custom filters/tags.
  Template.parse(
    String input, {
    Map<String, dynamic> data = const {},
    Root? root,
    Environment? environment,
    void Function(Environment)? environmentSetup,
  })  : _templateContent = input,
        _evaluator = Evaluator(
            _createEnvironment(data, environment, environmentSetup)
              ..setRoot(root));

  /// Renders the template with the current context.
  ///
  /// Returns the rendered output as a String.
  ///
  /// [clearBuffer] determines whether to clear the evaluator's buffer after rendering.
  /// If set to true (default), the buffer is cleared. If false, the buffer retains its content.
  /// Synchronously renders the template and returns the result.
  ///
  /// If [clearBuffer] is true (default), the internal buffer will be cleared after rendering.
  String render({bool clearBuffer = true}) {
    final parsed = parser.parseInput(_templateContent);
    _evaluator.evaluateNodes(parsed);
    final result = _evaluator.buffer.toString();
    if (clearBuffer) {
      _evaluator.buffer.clear();
    }
    return result;
  }

  /// Asynchronously renders the template and returns the result.
  ///
  /// This method should be used when the template contains async operations
  /// like file includes or custom async filters.
  ///
  /// If [clearBuffer] is true (default), the internal buffer will be cleared after rendering.
  Future<String> renderAsync({bool clearBuffer = true}) async {
    final parsed = parser.parseInput(_templateContent);
    if (clearBuffer) {
      _evaluator.buffer.clear();
    }
    await _evaluator.evaluateNodesAsync(parsed);
    final result = _evaluator.buffer.toString();

    return result;
  }

  /// Updates the template context with new data.
  ///
  /// [newData] is a map of variables to be merged into the existing context.
  void updateContext(Map<String, dynamic> newData) {
    _evaluator.context.merge(newData);
  }

  /// Gets the current environment used by this template.
  ///
  /// This allows access to the environment for registering additional
  /// filters or tags after template creation.
  Environment get environment => _evaluator.context;

  /// Helper method to create an environment based on the provided parameters.
  static Environment _createEnvironment(
    Map<String, dynamic> data,
    Environment? environment,
    void Function(Environment)? environmentSetup,
  ) {
    Environment env;

    if (environment != null) {
      // Use the provided environment, merge in any data
      env = environment.clone();
      env.merge(data);
    } else {
      // Create a new environment with the data
      env = Environment(data);
    }

    // Apply any environment setup callback
    if (environmentSetup != null) {
      environmentSetup(env);
    }

    return env;
  }
}
