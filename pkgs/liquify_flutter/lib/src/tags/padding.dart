import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class PaddingTag extends WidgetTagBase with AsyncTag {
  PaddingTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    setPropertyValue(evaluator.context, 'padding', _parseInsets(evaluator));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    setPropertyValue(evaluator.context, 'padding', _parseInsets(evaluator));
  }

  EdgeInsetsGeometry _parseInsets(Evaluator evaluator) {
    final values = <String, Object?>{};
    for (final arg in namedArgs) {
      values[arg.identifier.name] = evaluator.evaluate(arg.value);
    }
    return edgeInsetsFromNamedValues(values, sourceName: 'padding');
  }
}
