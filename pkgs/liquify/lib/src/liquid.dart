import 'package:liquify/src/ast.dart';
import 'package:liquify/src/config.dart';
import 'package:liquify/src/context.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/fs.dart';
import 'package:liquify/src/grammar/grammar.dart';
import 'package:liquify/src/registry.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/render_target.dart';
import 'package:liquify/src/tag_registry.dart';
import 'package:petitparser/petitparser.dart';

/// The main entry point for Liquid template parsing and rendering.
///
/// A [Liquid] instance holds configuration (including custom delimiters)
/// and provides methods to parse and render templates.
///
/// ## Basic Usage
///
/// ```dart
/// final liquid = Liquid();
/// final template = liquid.parse('Hello {{ name }}!');
/// final result = template.render({'name': 'World'});
/// print(result); // Hello World!
/// ```
///
/// ## Custom Delimiters
///
/// ```dart
/// final liquid = Liquid(
///   config: LiquidConfig(
///     tagStart: '[%',
///     tagEnd: '%]',
///     varStart: '[[',
///     varEnd: ']]',
///   ),
/// );
/// final template = liquid.parse('[% if user %]Hello [[name]]![% endif %]');
/// final result = template.render({'user': true, 'name': 'Alice'});
/// print(result); // Hello Alice!
/// ```
///
/// ## Convenience Constructor
///
/// ```dart
/// final liquid = Liquid.withDelimiters(
///   tagStart: '<%',
///   tagEnd: '%>',
///   varStart: '<%=',
///   varEnd: '%>',
/// );
/// ```
///
/// ## One-Shot Rendering
///
/// For templates rendered only once, use [renderString]:
///
/// ```dart
/// final liquid = Liquid();
/// final result = liquid.renderString('Hello {{ name }}!', {'name': 'World'});
/// ```
///
/// ## File-Based Templates
///
/// ```dart
/// final liquid = Liquid(root: Root.fs('/templates'));
/// final template = liquid.parseFile('greeting.liquid');
/// final result = template.render({'name': 'World'});
/// ```
///
/// ## Multiple Instances
///
/// You can create multiple [Liquid] instances with different configurations:
///
/// ```dart
/// final standard = Liquid(); // Default delimiters
/// final erb = Liquid(config: LiquidConfig.erb); // ERB-style
/// final custom = Liquid.withDelimiters(tagStart: '<<', tagEnd: '>>');
/// ```
///
/// See also:
/// - [LiquidConfig] for delimiter configuration options
/// - [LiquidTemplate] for template rendering methods
/// - [Template] for the legacy API (uses default delimiters only)
class Liquid {
  /// The configuration for this Liquid instance.
  final LiquidConfig config;

  /// Optional file system root for resolving templates.
  final Root? root;

  // Cached parser for this configuration
  Parser? _cachedParser;
  int? _cachedSignature;

  /// Creates a new [Liquid] instance with the given configuration.
  ///
  /// If [config] is not provided, standard Liquid delimiters are used.
  /// If [root] is provided, it will be used to resolve file-based templates.
  Liquid({this.config = const LiquidConfig(), this.root});

  /// Creates a [Liquid] instance with custom delimiters.
  ///
  /// This is a convenience constructor for common use cases.
  ///
  /// Example:
  /// ```dart
  /// final liquid = Liquid.withDelimiters(
  ///   tagStart: '[%',
  ///   tagEnd: '%]',
  ///   varStart: '[[',
  ///   varEnd: ']]',
  /// );
  /// ```
  factory Liquid.withDelimiters({
    String tagStart = '{%',
    String tagEnd = '%}',
    String varStart = '{{',
    String varEnd = '}}',
    String stripMarker = '-',
    Root? root,
  }) {
    return Liquid(
      config: LiquidConfig(
        tagStart: tagStart,
        tagEnd: tagEnd,
        varStart: varStart,
        varEnd: varEnd,
        stripMarker: stripMarker,
      ),
      root: root,
    );
  }

  /// Parses a template string and returns a [LiquidTemplate].
  ///
  /// The returned template can be rendered multiple times with different data.
  ///
  /// Throws [ParsingException] if the template contains syntax errors.
  LiquidTemplate parse(String source) {
    if (source.isEmpty) {
      return LiquidTemplate._([], this);
    }

    final parser = _getParser();
    final result = parser.parse(source);

    if (result is Success) {
      return LiquidTemplate._((result.value as Document).children, this);
    }

    final lineCol = Token.lineAndColumnOf(source, result.position);
    throw ParsingException(
      result.message,
      source,
      lineCol[0],
      lineCol[1],
      result.position,
    );
  }

  /// Parses a template from a file.
  ///
  /// Requires a [Root] to be configured either in the constructor or passed
  /// as a parameter.
  ///
  /// Throws [StateError] if no root is configured.
  /// Throws [TemplateNotFoundException] if the file cannot be found.
  LiquidTemplate parseFile(String filename, [Root? fileRoot]) {
    final resolvedRoot = fileRoot ?? root;
    if (resolvedRoot == null) {
      throw StateError(
        'No Root configured. Pass a Root to parseFile() or configure one in the Liquid constructor.',
      );
    }

    final source = resolvedRoot.resolve(filename);
    final template = parse(source.content);
    template._root = resolvedRoot;
    return template;
  }

  /// Convenience method to parse and render a template in one step.
  ///
  /// For templates that will be rendered multiple times, use [parse] instead
  /// to avoid re-parsing.
  String renderString(String source, [Map<String, dynamic> data = const {}]) {
    return parse(source).render(data);
  }

  /// Convenience method to parse and render a template asynchronously.
  Future<String> renderStringAsync(
    String source, [
    Map<String, dynamic> data = const {},
  ]) {
    return parse(source).renderAsync(data);
  }

  Parser _getParser() {
    registerBuiltIns();
    final signature = _parserSignature();
    if (_cachedParser == null || _cachedSignature != signature) {
      _cachedParser = LiquidGrammar(config).build();
      _cachedSignature = signature;
    }
    return _cachedParser!;
  }

  int _parserSignature() {
    // Include config in signature so parser is rebuilt if config changes
    final customParsers = TagRegistry.customParsers;
    return Object.hash(
      config,
      Object.hashAll(customParsers.map((p) => p.runtimeType)),
    );
  }
}

/// A parsed Liquid template that can be rendered with different data.
///
/// Create instances using [Liquid.parse] or [Liquid.parseFile].
///
/// ## Basic Rendering
///
/// ```dart
/// final liquid = Liquid();
/// final template = liquid.parse('Hello {{ name }}!');
///
/// // Render with data
/// print(template.render({'name': 'World'})); // Hello World!
///
/// // Render multiple times with different data
/// print(template.render({'name': 'Alice'})); // Hello Alice!
/// print(template.render({'name': 'Bob'}));   // Hello Bob!
/// ```
///
/// ## Async Rendering
///
/// Use [renderAsync] when the template may contain async operations:
///
/// ```dart
/// final result = await template.renderAsync({'name': 'World'});
/// ```
///
/// ## Custom Environment
///
/// ```dart
/// final result = template.render(
///   {'name': 'World'},
///   null,
///   (env) {
///     env.registerLocalFilter('shout', (value, args, namedArgs) =>
///       value.toString().toUpperCase());
///   },
/// );
/// ```
///
/// ## Render to Custom Target
///
/// ```dart
/// final result = template.renderTo(
///   MyRenderTarget(),
///   {'name': 'World'},
/// );
/// ```
class LiquidTemplate {
  final List<ASTNode> _nodes;
  final Liquid _liquid;
  Root? _root;

  LiquidTemplate._(this._nodes, this._liquid);

  /// The configuration used to parse this template.
  LiquidConfig get config => _liquid.config;

  /// Renders the template with the given data.
  ///
  /// [data] is a map of variables available in the template.
  /// [environment] optionally provides a custom environment with filters/tags.
  /// [environmentSetup] optionally configures the environment before rendering.
  String render([
    Map<String, dynamic> data = const {},
    Environment? environment,
    void Function(Environment)? environmentSetup,
  ]) {
    final env = _createEnvironment(data, environment, environmentSetup);
    final evaluator = Evaluator(env);
    evaluator.evaluateNodes(_nodes);
    return evaluator.buffer.toString();
  }

  /// Renders the template asynchronously.
  ///
  /// Use this when the template contains async operations like file includes.
  Future<String> renderAsync([
    Map<String, dynamic> data = const {},
    Environment? environment,
    void Function(Environment)? environmentSetup,
  ]) async {
    final env = _createEnvironment(data, environment, environmentSetup);
    final evaluator = Evaluator(env);
    await evaluator.evaluateNodesAsync(_nodes);
    return evaluator.buffer.toString();
  }

  /// Renders the template to a custom target.
  R renderTo<R>(
    RenderTarget<R> target, [
    Map<String, dynamic> data = const {},
    Environment? environment,
    void Function(Environment)? environmentSetup,
  ]) {
    final env = _createEnvironment(data, environment, environmentSetup);
    final evaluator = Evaluator(env);
    final sink = target.createSink();
    final buffer = Buffer(sink: sink);
    return evaluator.withBuffer(buffer, () {
      evaluator.evaluateNodes(_nodes);
      return target.finalize(sink);
    });
  }

  Environment _createEnvironment(
    Map<String, dynamic> data,
    Environment? environment,
    void Function(Environment)? environmentSetup,
  ) {
    Environment env;
    if (environment != null) {
      env = environment.clone();
      env.merge(data);
    } else {
      env = Environment(data);
    }

    // Set the config so tags can use it for re-parsing
    env.setConfig(_liquid.config);

    if (_root != null) {
      env.setRoot(_root);
    }

    if (environmentSetup != null) {
      environmentSetup(env);
    }

    return env;
  }
}

/// Represents an exception that occurred during parsing.
class ParsingException implements Exception {
  final String message;
  final String source;
  final int line;
  final int column;
  final int offset;

  ParsingException(
    this.message,
    this.source,
    this.line,
    this.column,
    this.offset,
  );

  @override
  String toString() {
    final lines = source.split('\n');
    final errorLine = line <= lines.length ? lines[line - 1] : '';
    final pointer = '${' ' * (column - 1)}^';
    return 'ParsingException: $message @ line $line:$column\nsource: \n$errorLine\n$pointer';
  }
}
