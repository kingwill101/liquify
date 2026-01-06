import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class CheckboxTag extends WidgetTagBase with AsyncTag {
  CheckboxTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildCheckbox(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildCheckbox(config));
  }

  _CheckboxConfig _parseConfig(Evaluator evaluator) {
    final config = _CheckboxConfig();
    Object? actionValue;
    Object? onChangedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'value':
          config.value = toBool(value);
          break;
        case 'label':
        case 'text':
          config.label = value?.toString();
          break;
        case 'tristate':
          config.tristate = toBool(value);
          break;
        case 'activeColor':
          config.activeColor = parseColor(value);
          break;
        case 'checkColor':
          config.checkColor = parseColor(value);
          break;
        case 'dense':
          config.dense = toBool(value);
          break;
        case 'contentPadding':
          config.contentPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'controlAffinity':
          config.controlAffinity = parseListTileControlAffinity(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onChanged':
          onChangedValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('checkbox', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'checkbox',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final resolvedKeyValue =
        (widgetKeyValue != null && widgetKeyValue.trim().isNotEmpty)
        ? widgetKeyValue.trim()
        : resolvedId;
    config.widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'checkbox',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {'label': config.label},
    );
    final callback =
        resolveBoolActionCallback(
          evaluator,
          onChangedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveBoolActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    config.onChanged = callback == null
        ? null
        : (value) {
            baseEvent['value'] = value;
            callback(value);
          };
    return config;
  }
}

class _CheckboxConfig {
  bool? value;
  String? label;
  bool? tristate;
  Color? activeColor;
  Color? checkColor;
  bool? dense;
  EdgeInsetsGeometry? contentPadding;
  ListTileControlAffinity? controlAffinity;
  ValueChanged<bool>? onChanged;
  Key? widgetKey;
}

Widget _buildCheckbox(_CheckboxConfig config) {
  if (config.value == null) {
    throw Exception('checkbox tag requires "value"');
  }
  final checkbox = Checkbox(
    key: config.widgetKey,
    value: config.value,
    tristate: config.tristate ?? false,
    activeColor: config.activeColor,
    checkColor: config.checkColor,
    onChanged: config.onChanged == null
        ? null
        : (value) {
            if (value != null) {
              config.onChanged!(value);
            }
          },
  );
  if (config.label == null || config.label!.trim().isEmpty) {
    return checkbox;
  }
  return CheckboxListTile(
    key: config.widgetKey,
    value: config.value,
    title: Text(config.label!),
    tristate: config.tristate ?? false,
    activeColor: config.activeColor,
    checkColor: config.checkColor,
    onChanged: config.onChanged == null
        ? null
        : (value) {
            if (value != null) {
              config.onChanged!(value);
            }
          },
    dense: config.dense,
    contentPadding: config.contentPadding,
    controlAffinity: config.controlAffinity,
  );
}
