import 'package:liquify/src/tag.dart';

class DecrementTag extends AbstractTag {
  late String variableName;

  DecrementTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty) {
      throw Exception('DecrementTag requires a variable name.');
    }

    final arg = content.first;
    if (arg is! Identifier) {
      throw Exception('DecrementTag argument must be an identifier.');
    }

    variableName = arg.name;
  }

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final stateKey = 'decrement:$variableName';
    var currentValue = evaluator.context.getVariable(stateKey) as int?;

    if (currentValue == null) {
      currentValue = -1; // Initial value is -1 for decrement
    } else {
      currentValue -= 1; // Decrease by 1 on subsequent calls
    }

    evaluator.context.setVariable(stateKey, currentValue);
    buffer.write(currentValue.toString());
  }
}
