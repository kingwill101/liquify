import 'package:liquify/src/tag.dart';

class CaptureTag extends AbstractTag with CustomTagParser, AsyncTag {
  late String variableName;

  CaptureTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! Identifier) {
      throw Exception(
        'CaptureTag requires a variable name as the first argument.',
      );
    }
    variableName = (content.first as Identifier).name;
  }

  Future<dynamic> _evaluateCapture(
    Evaluator evaluator,
    Buffer buffer, {
    bool isAsync = false,
  }) async {
    if (variableName.isEmpty) {
      return '';
    }

    evaluator.startBlockCapture();
    if (isAsync) {
      await evaluator.evaluateNodesAsync(body);
    } else {
      evaluator.evaluateNodes(body);
    }
    final captured = evaluator.endBlockCapture();
    evaluator.context.setVariable(variableName, captured);
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    return _evaluateCapture(evaluator, buffer, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    return _evaluateCapture(evaluator, buffer, isAsync: true);
  }

  @override
  Parser parser() {
    return seq3(
      tagStart() & string('capture').trim(),
      ref0(identifier).trim(),
      tagEnd(),
    ).map((values) {
      return Tag('capture', [values.$2 as ASTNode]);
    });
  }
}
