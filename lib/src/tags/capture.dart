import 'package:liquify/src/tag.dart';

class CaptureTag extends AbstractTag with CustomTagParser {
  late String variableName;

  CaptureTag(super.content, super.filters);

  @override
  Future<void> preprocess(Evaluator evaluator) async {
    if (content.isEmpty || content.first is! Identifier) {
      throw Exception(
          'CaptureTag requires a variable name as the first argument.');
    }
    variableName = (content.first as Identifier).name;
  }

  @override
  Future<dynamic> evaluate(
      Evaluator evaluator, Buffer buffer) async {
    Buffer buf = Buffer();
    final variable = args.firstOrNull;
    if (variable == null) return;
    for (final node in body) {
      if (node is Tag) continue;
      final result = await evaluator.evaluate(node);
      if (result != null) {
        buf.write(result);
      }
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
