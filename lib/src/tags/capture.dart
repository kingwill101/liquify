import 'package:liquify/src/tag.dart';

@TagMacro(name: 'capture', hasEndTag: true)
class CaptureTag extends AbstractTag with CustomTagParser {
  CaptureTag(super.content, super.filters);

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
}
