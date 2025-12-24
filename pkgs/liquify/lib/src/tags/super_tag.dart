import 'package:liquify/parser.dart';

/// A tag that represents a call to the parent block's content.
/// The super content is now handled by the analyzer and resolver.
class SuperTag extends AbstractTag with CustomTagParser {
  SuperTag(super.content, super.filters);

  @override
  dynamic evaluateContent(Evaluator evaluator) {
    // Super content is now handled by the analyzer and resolver
    // This tag is only used for parsing and AST construction
    return '';
  }

  @override
  Parser parser() {
    // This matches syntax: {{ super() }}
    return (varStart() &
            string('super').trim() &
            char('(').trim() &
            char(')').trim() &
            varEnd())
        .map((_) {
      return Tag('super', []);
    });
  }
}
