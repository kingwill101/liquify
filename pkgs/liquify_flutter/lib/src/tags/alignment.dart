import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AlignmentTag extends WidgetTagBase with AsyncTag {
  AlignmentTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    setPropertyValue(
      evaluator.context,
      'alignment',
      _parseAlignment(evaluator),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    setPropertyValue(
      evaluator.context,
      'alignment',
      _parseAlignment(evaluator),
    );
  }

  AlignmentGeometry? _parseAlignment(Evaluator evaluator) {
    Object? value;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'value':
        case 'alignment':
          value = evaluator.evaluate(arg.value);
          break;
        default:
          handleUnknownArg('alignment', name);
          break;
      }
    }
    value ??= evaluatePositionalValue(evaluator, content);
    return parseAlignmentGeometry(value);
  }
}
