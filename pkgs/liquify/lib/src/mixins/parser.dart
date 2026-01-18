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
  /// Override this to return [TagDelimiterType.variable] if your custom tag
  /// uses {{ }} syntax instead of {% %}.
  TagDelimiterType get delimiterType => TagDelimiterType.tag;
}
