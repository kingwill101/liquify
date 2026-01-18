import 'package:petitparser/petitparser.dart';

/// Indicates the delimiter type used by a custom tag parser.
enum TagDelimiterType {
  /// Uses {% %} delimiters (standard tag syntax)
  tag,

  /// Uses {{ }} delimiters (variable-like syntax, e.g., {{ super() }})
  variable,
}

mixin CustomTagParser {
  Parser parser() {
    return epsilon();
  }

  /// The delimiter type this tag uses.
  ///
  /// Defaults to [TagDelimiterType.tag] for standard {% %} syntax.
  /// Override to [TagDelimiterType.variable] if your custom tag
  /// uses {{ }} syntax instead (e.g., {{ super() }}).
  ///
  /// **Breaking change in 2.0.0:** Custom tags using {{ }} syntax must now
  /// explicitly override this getter to return [TagDelimiterType.variable].
  TagDelimiterType get delimiterType => TagDelimiterType.tag;
}
