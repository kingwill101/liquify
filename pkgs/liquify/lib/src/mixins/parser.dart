import 'package:liquify/src/config.dart';
import 'package:petitparser/petitparser.dart';

/// Indicates the delimiter type used by a custom tag parser.
enum TagDelimiterType {
  /// Uses {% %} delimiters (standard tag syntax)
  tag,

  /// Uses {{ }} delimiters (variable-like syntax, e.g., {{ super() }})
  variable,
}

/// Mixin for custom tag parsers.
///
/// Implement this mixin to create custom tags with custom parsing logic.
///
/// ## Basic Usage
///
/// ```dart
/// class MyTag extends AbstractTag with CustomTagParser {
///   MyTag(super.content, super.filters);
///
///   @override
///   Parser parser([LiquidConfig? config]) {
///     return someTag('mytag', config: config);
///   }
/// }
/// ```
///
/// ## Custom Delimiters
///
/// When [parser] is called with a [LiquidConfig], use the factory functions
/// with that config to support custom delimiters:
///
/// ```dart
/// @override
/// Parser parser([LiquidConfig? config]) {
///   return (createTagStart(config) &
///           string('mytag').trim() &
///           createTagEnd(config))
///       .map((_) => Tag('mytag', []));
/// }
/// ```
///
/// ## Accessing Config During Evaluation
///
/// If your tag needs to re-parse content (e.g., a block tag with nested Liquid
/// syntax), access the config from the evaluator's context:
///
/// ```dart
/// @override
/// dynamic evaluate(Evaluator evaluator, Buffer buffer) {
///   final content = body[0].toString();
///
///   // Get the config to use the same delimiters as the parent template
///   final config = evaluator.context.config;
///   final liquid = Liquid(config: config ?? LiquidConfig.standard);
///
///   // Re-parse and render with the correct delimiters
///   final result = liquid.renderString(content, evaluator.context.all());
///   buffer.write(result);
/// }
/// ```
///
/// ## Variable-Style Tags
///
/// For tags that use `{{ }}` syntax (like `{{ super() }}`), override
/// [delimiterType] to return [TagDelimiterType.variable]:
///
/// ```dart
/// @override
/// TagDelimiterType get delimiterType => TagDelimiterType.variable;
///
/// @override
/// Parser parser([LiquidConfig? config]) {
///   return (createVarStart(config) &
///           string('super').trim() &
///           char('(').trim() &
///           char(')').trim() &
///           createVarEnd(config))
///       .map((_) => Tag('super', []));
/// }
/// ```
mixin CustomTagParser {
  /// Returns the parser for this custom tag.
  ///
  /// Override this method to define the parsing logic for your custom tag.
  ///
  /// The optional [config] parameter provides the delimiter configuration.
  /// When building parsers, use the factory functions with this config:
  /// - [createTagStart], [createTagEnd] for tag delimiters
  /// - [createVarStart], [createVarEnd] for variable delimiters
  /// - [someTag] for complete tag parsers
  ///
  /// If [config] is null, standard Liquid delimiters are used.
  Parser parser([LiquidConfig? config]) {
    return epsilon();
  }

  /// The delimiter type this tag uses.
  ///
  /// Defaults to [TagDelimiterType.tag] for standard {% %} syntax.
  /// Override to [TagDelimiterType.variable] if your custom tag
  /// uses {{ }} syntax instead (e.g., {{ super() }}).
  TagDelimiterType get delimiterType => TagDelimiterType.tag;
}
