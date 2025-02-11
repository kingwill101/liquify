import 'package:liquify/src/tag.dart';

class IncrementTag extends AbstractTag with AsyncTag {
  IncrementTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty || content.first is! Identifier) {
      throw Exception('IncrementTag requires a variable name as argument.');
    }
  }

  String _getStateKey() {
    return 'counter:${(content.first as Identifier).name}';
  }

  Future<dynamic> _evaluateIncrement(Evaluator evaluator, Buffer buffer,
      {bool isAsync = false}) async {
    final stateKey = _getStateKey();
    final currentValue = evaluator.context.getVariable(stateKey) ?? -1;
    final newValue = currentValue + 1;

    buffer.write(newValue);
    evaluator.context.setVariable(stateKey, newValue);
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    return _evaluateIncrement(evaluator, buffer, isAsync: false);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    return _evaluateIncrement(evaluator, buffer, isAsync: true);
  }
}
