import 'package:liquify/src/tag.dart';

class IncrementTag extends AbstractTag {
  late String variableName;

  IncrementTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty) {
      throw Exception('IncrementTag requires a variable name.');
    }

    final arg = content.first;
    if (arg is! Identifier) {
      throw Exception('IncrementTag argument must be an identifier.');
    }

    variableName = arg.name;
  }

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final stateKey = 'increment:$variableName';
    var currentValue = evaluator.context.getVariable(stateKey) as int?;

    if (currentValue == null) {
      currentValue = 0;
    } else {
      currentValue += 1;
    }

    evaluator.context.setVariable(stateKey, currentValue);
    buffer.write(currentValue.toString());
  }
}
