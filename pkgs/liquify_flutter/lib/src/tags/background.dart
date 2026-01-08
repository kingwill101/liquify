import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class BackgroundTag extends WidgetTagBase with AsyncTag {
  BackgroundTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final color = _parseColor(evaluator);
    if (color != null) {
      setPropertyValue(evaluator.context, 'color', color);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final color = _parseColor(evaluator);
    if (color != null) {
      setPropertyValue(evaluator.context, 'color', color);
    }
  }

  Color? _parseColor(Evaluator evaluator) {
    Object? value;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'color':
        case 'value':
          value = evaluator.evaluate(arg.value);
          break;
        default:
          handleUnknownArg('background', name);
          break;
      }
    }
    value ??= evaluatePositionalValue(evaluator, content);
    return parseColor(value);
  }
}
