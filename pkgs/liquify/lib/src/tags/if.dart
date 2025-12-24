import 'package:liquify/src/ast.dart';
import 'package:liquify/src/buffer.dart';
import 'package:liquify/src/evaluator.dart';
import 'package:liquify/src/exceptions.dart';
import 'package:liquify/src/tags/tag.dart';
import 'package:liquify/src/util.dart';

class IfTag extends AbstractTag with AsyncTag {
  bool conditionMet = false;

  IfTag(super.content, super.filters);

  void _renderBlockSync(
      Evaluator evaluator, Buffer buffer, List<ASTNode> body) {
    for (final subNode in body) {
      if (subNode is Tag &&
          (subNode.name == 'else' || subNode.name == 'elsif')) {
        continue;
      }

      try {
        if (subNode is Tag) {
          evaluator.evaluate(subNode);
        } else {
          buffer.write(evaluator.evaluate(subNode));
        }
      } on BreakException {
        throw BreakException();
      } on ContinueException {
        throw ContinueException();
      }
    }
  }

  Future<void> _renderBlockAsync(
      Evaluator evaluator, Buffer buffer, List<ASTNode> body) async {
    for (final subNode in body) {
      if (subNode is Tag &&
          (subNode.name == 'else' || subNode.name == 'elsif')) {
        continue;
      }

      try {
        if (subNode is Tag) {
          await evaluator.evaluateAsync(subNode);
        } else {
          buffer.write(await evaluator.evaluateAsync(subNode));
        }
      } on BreakException {
        throw BreakException();
      } on ContinueException {
        throw ContinueException();
      }
    }
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    // Get main condition result
    conditionMet = isTruthy(evaluator.evaluate(content[0]));

    // Get all else/elsif blocks
    final elseBlock =
        body.where((n) => n is Tag && n.name == 'else').firstOrNull as Tag?;
    final elsifTags =
        body.where((n) => n is Tag && (n.name == 'elsif')).cast<Tag>().toList();

    // Main if condition
    if (conditionMet) {
      // Filter out else/elsif nodes from main body evaluation
      final mainBody = body
          .where((n) => !(n is Tag && (n.name == 'else' || n.name == 'elsif')))
          .toList();
      _renderBlockSync(evaluator, buffer, mainBody);
      return;
    }

    // Try elsif conditions in order
    for (var elsif in elsifTags) {
      if (elsif.content.isEmpty) continue;

      final elIfConditionMet = isTruthy(evaluator.evaluate(elsif.content[0]));
      if (elIfConditionMet) {
        _renderBlockSync(evaluator, buffer, elsif.body);
        return;
      }
    }

    // Fallback to else block
    if (elseBlock != null) {
      _renderBlockSync(evaluator, buffer, elseBlock.body);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
      Evaluator evaluator, Buffer buffer) async {
    // Get main condition result
    conditionMet = isTruthy(await evaluator.evaluateAsync(content[0]));

    // Get all else/elsif blocks
    final elseBlock =
        body.where((n) => n is Tag && n.name == 'else').firstOrNull as Tag?;
    final elsifTags =
        body.where((n) => n is Tag && (n.name == 'elsif')).cast<Tag>().toList();

    // Main if condition
    if (conditionMet) {
      // Filter out else/elsif nodes from main body evaluation
      final mainBody = body
          .where((n) => !(n is Tag && (n.name == 'else' || n.name == 'elsif')))
          .toList();
      await _renderBlockAsync(evaluator, buffer, mainBody);
      return;
    }

    // Try elsif conditions in order
    for (var elsif in elsifTags) {
      if (elsif.content.isEmpty) continue;

      final elIfConditionMet =
          isTruthy(await evaluator.evaluateAsync(elsif.content[0]));
      if (elIfConditionMet) {
        await _renderBlockAsync(evaluator, buffer, elsif.body);
        return;
      }
    }

    // Fallback to else block
    if (elseBlock != null) {
      await _renderBlockAsync(evaluator, buffer, elseBlock.body);
    }
  }
}
