import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SnackBarActionTag extends WidgetTagBase with AsyncTag {
  SnackBarActionTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    setPropertyValue(evaluator.context, 'action', _buildAction(evaluator));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    setPropertyValue(evaluator.context, 'action', _buildAction(evaluator));
  }

  SnackBarAction _buildAction(Evaluator evaluator) {
    Object? labelValue;
    Object? actionValue;
    Object? onPressedValue;
    Color? textColor;
    Color? disabledTextColor;
    String? widgetIdValue;
    String? widgetKeyValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
        case 'text':
        case 'value':
          labelValue = value;
          break;
        case 'textColor':
          textColor = parseColor(value);
          break;
        case 'disabledTextColor':
          disabledTextColor = parseColor(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onPressed':
          onPressedValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('snack_bar_action', name);
          break;
      }
    }

    labelValue ??= evaluatePositionalValue(evaluator, content);
    final label = labelValue?.toString() ?? '';

    final ids = resolveIds(
      evaluator,
      'snack_bar_action',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'snack_bar_action',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'pressed',
    );
    final onPressed =
        resolveActionCallback(
          evaluator,
          onPressedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );

    return SnackBarAction(
      key: ids.key,
      label: label,
      textColor: textColor,
      disabledTextColor: disabledTextColor,
      onPressed: onPressed ?? () {},
    );
  }
}
