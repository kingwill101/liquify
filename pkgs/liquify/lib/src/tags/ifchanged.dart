import 'package:liquify/src/tag.dart';

class IfChangedTag extends AbstractTag with AsyncTag {
  IfChangedTag(super.content, super.filters);

  @override
  void evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
    } finally {
      _writeChanged(evaluator, buffer, evaluator.endBlockCapture());
    }
  }

  @override
  Future<void> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
    } finally {
      _writeChanged(evaluator, buffer, evaluator.endBlockCapture());
    }
  }

  void _writeChanged(Evaluator evaluator, Buffer buffer, String output) {
    final state =
        evaluator.context.registers.putIfAbsent(
              'ifchanged',
              () => <String, String>{},
            )
            as Map<String, String>;
    if (state['output'] == output) return;
    state['output'] = output;
    buffer.write(output);
  }
}
