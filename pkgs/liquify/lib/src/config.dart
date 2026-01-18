/// Configuration for Liquid template parsing.
///
/// This class holds delimiter configuration and other parser options.
/// Create instances to customize how templates are parsed.
///
/// ## Basic Usage
///
/// ```dart
/// // Custom delimiters
/// final config = LiquidConfig(
///   tagStart: '[%',
///   tagEnd: '%]',
///   varStart: '[[',
///   varEnd: ']]',
/// );
///
/// final liquid = Liquid(config: config);
/// final template = liquid.parse('[% if user %]Hello [[name]]![% endif %]');
/// print(template.render({'user': true, 'name': 'Alice'})); // Hello Alice!
/// ```
///
/// ## Presets
///
/// Two presets are available for common use cases:
///
/// ```dart
/// // Standard Liquid delimiters (default)
/// final standard = LiquidConfig.standard;
/// // Uses: {% %} for tags, {{ }} for variables
///
/// // ERB-style delimiters
/// final erb = LiquidConfig.erb;
/// // Uses: <% %> for tags, <%= %> for variables
/// ```
///
/// ## Whitespace Control
///
/// The [stripMarker] (default: `-`) enables whitespace stripping when placed
/// inside delimiters:
///
/// ```dart
/// final liquid = Liquid();
/// final template = liquid.parse('''
///   {%- if true -%}
///     Hello
///   {%- endif -%}
/// ''');
/// print(template.render()); // 'Hello' (whitespace stripped)
/// ```
///
/// ## Building Custom Tags
///
/// When building custom tags, use the factory functions with your config:
///
/// ```dart
/// final config = LiquidConfig(tagStart: '[%', tagEnd: '%]');
///
/// // Create a custom tag parser
/// Parser myTagParser() {
///   return someTag('mytag', config: config);
/// }
/// ```
///
/// See also:
/// - [Liquid] for parsing templates with custom delimiters
/// - [LiquidTemplate] for rendering parsed templates
/// - [createTagStart], [createTagEnd], [createVarStart], [createVarEnd] for
///   building custom parsers
class LiquidConfig {
  /// The opening delimiter for tags. Default: `{%`
  final String tagStart;

  /// The closing delimiter for tags. Default: `%}`
  final String tagEnd;

  /// The opening delimiter for variable output. Default: `{{`
  final String varStart;

  /// The closing delimiter for variable output. Default: `}}`
  final String varEnd;

  /// The marker used for whitespace stripping. Default: `-`
  ///
  /// When placed inside a delimiter (e.g., `{{-` or `-%}`), it strips
  /// whitespace from the adjacent text.
  final String stripMarker;

  /// Creates a new [LiquidConfig] with the specified delimiters.
  ///
  /// All parameters are optional and default to standard Liquid delimiters.
  const LiquidConfig({
    this.tagStart = '{%',
    this.tagEnd = '%}',
    this.varStart = '{{',
    this.varEnd = '}}',
    this.stripMarker = '-',
  });

  /// Standard Liquid delimiters (default).
  ///
  /// Uses `{% %}` for tags and `{{ }}` for variable output.
  ///
  /// ```dart
  /// final liquid = Liquid(config: LiquidConfig.standard);
  /// // Equivalent to: final liquid = Liquid();
  /// ```
  static const standard = LiquidConfig();

  /// ERB-style delimiters.
  ///
  /// Uses `<% %>` for tags and `<%= %>` for variable output, similar to
  /// Ruby's ERB templating system.
  ///
  /// ```dart
  /// final liquid = Liquid(config: LiquidConfig.erb);
  /// final template = liquid.parse('<% if user %>Hello <%= name %>!<% endif %>');
  /// print(template.render({'user': true, 'name': 'World'})); // Hello World!
  /// ```
  static const erb = LiquidConfig(
    tagStart: '<%',
    tagEnd: '%>',
    varStart: '<%=',
    varEnd: '%>',
  );

  // Computed whitespace-stripping delimiter variants

  /// Tag start with whitespace stripping (e.g., `{%-`)
  String get tagStartStrip => '$tagStart$stripMarker';

  /// Tag end with whitespace stripping (e.g., `-%}`)
  String get tagEndStrip => '$stripMarker$tagEnd';

  /// Variable start with whitespace stripping (e.g., `{{-`)
  String get varStartStrip => '$varStart$stripMarker';

  /// Variable end with whitespace stripping (e.g., `-}}`)
  String get varEndStrip => '$stripMarker$varEnd';

  /// Returns the first character(s) that could start a delimiter.
  ///
  /// Used by the text parser to know when to stop consuming text.
  String get delimiterStartChars {
    final chars = <String>{};
    if (tagStart.isNotEmpty) chars.add(tagStart[0]);
    if (varStart.isNotEmpty) chars.add(varStart[0]);
    return chars.join();
  }

  /// Creates a copy of this config with the specified fields replaced.
  ///
  /// ```dart
  /// final custom = LiquidConfig.standard.copyWith(
  ///   tagStart: '<%',
  ///   tagEnd: '%>',
  /// );
  /// // custom uses <% %> for tags but {{ }} for variables
  /// ```
  LiquidConfig copyWith({
    String? tagStart,
    String? tagEnd,
    String? varStart,
    String? varEnd,
    String? stripMarker,
  }) {
    return LiquidConfig(
      tagStart: tagStart ?? this.tagStart,
      tagEnd: tagEnd ?? this.tagEnd,
      varStart: varStart ?? this.varStart,
      varEnd: varEnd ?? this.varEnd,
      stripMarker: stripMarker ?? this.stripMarker,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidConfig &&
        other.tagStart == tagStart &&
        other.tagEnd == tagEnd &&
        other.varStart == varStart &&
        other.varEnd == varEnd &&
        other.stripMarker == stripMarker;
  }

  @override
  int get hashCode {
    return Object.hash(tagStart, tagEnd, varStart, varEnd, stripMarker);
  }

  @override
  String toString() {
    return 'LiquidConfig(tagStart: $tagStart, tagEnd: $tagEnd, '
        'varStart: $varStart, varEnd: $varEnd, stripMarker: $stripMarker)';
  }
}
