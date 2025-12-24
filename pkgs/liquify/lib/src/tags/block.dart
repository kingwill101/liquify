import 'package:liquify/parser.dart';

/// A tag that defines a block in a template. Used with layout inheritance.
/// The block content is now handled by the analyzer and resolver.
class BlockTag extends AbstractTag with CustomTagParser {
  late String name;

  BlockTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! Identifier) {
      throw Exception('BlockTag requires a name as first argument');
    }
    name = (content.first as Identifier).name;
  }

  @override
  dynamic evaluateContent(Evaluator evaluator) {
    // Block content is now handled by the analyzer and resolver
    // This tag is only used for parsing and AST construction
    return '';
  }

  @override
  Parser parser() {
    return ((tagStart() &
                string('block').trim() &
                ref0(identifier).trim() &
                tagEnd()) &
            ref0(element)
                .starLazy(tagStart() & string('endblock').trim() & tagEnd()) &
            (tagStart() & string('endblock').trim() & tagEnd()))
        .map((values) {
      final tag =
          Tag('block', [values[2] as ASTNode], body: values[4].cast<ASTNode>());
      return tag;
    });
  }
}
