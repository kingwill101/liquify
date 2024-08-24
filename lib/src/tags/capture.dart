import 'package:liquify/src/tag.dart';

class CaptureTag extends AbstractTag with CustomTagParser {
  late String variableName;

  CaptureTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! Identifier) {
      throw Exception(
          'CaptureTag requires a variable name as the first argument.');
    }
    variableName = (content.first as Identifier).name;
  }

  @override
  evaluate(Evaluator evaluator, Buffer buffer) {
    Buffer buf = Buffer();
    final variable = args.firstOrNull;
    if (variable == null) return;
    for (final node in body) {
      if (node is Tag) continue;
      buf.write(evaluator.evaluate(node));
    }
    evaluator.context.setVariable(variable.name, buf.toString());
  }

  @override
  Parser parser() {
    return seq3(tagStart() & string('capture').trim(), ref0(identifier).trim(),
            tagEnd())
        .map((values) {
      return Tag('capture', [values.$2 as ASTNode]);
    });
  }
}
