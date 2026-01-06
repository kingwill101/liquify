// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class RadioTag extends WidgetTagBase with AsyncTag {
  RadioTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildRadio(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildRadio(config));
  }

  _RadioConfig _parseConfig(Evaluator evaluator) {
    final config = _RadioConfig();
    Object? actionValue;
    Object? onChangedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'value':
          config.value = value?.toString();
          break;
        case 'group':
        case 'groupValue':
          config.groupValue = value?.toString();
          break;
        case 'label':
        case 'text':
          config.label = value?.toString();
          break;
        case 'toggleable':
          config.toggleable = toBool(value);
          break;
        case 'activeColor':
          config.activeColor = parseColor(value);
          break;
        case 'fillColor':
          config.fillColor = toWidgetStateColor(value);
          break;
        case 'focusColor':
          config.focusColor = parseColor(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'splashRadius':
          config.splashRadius = toDouble(value);
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
          handleUnknownArg('radio', name);
          break;
      }
    }

    if (config.value == null || config.value!.trim().isEmpty) {
      throw Exception('radio tag requires "value"');
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'radio',
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
      tag: 'radio',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {'label': config.label, 'group': config.groupValue},
    );
    final callback =
        resolveStringActionCallback(
          evaluator,
          onChangedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveStringActionCallback(
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

class _RadioConfig {
  String? value;
  String? groupValue;
  String? label;
  bool? toggleable;
  Color? activeColor;
  WidgetStateProperty<Color?>? fillColor;
  Color? focusColor;
  Color? hoverColor;
  double? splashRadius;
  bool? dense;
  EdgeInsetsGeometry? contentPadding;
  ListTileControlAffinity? controlAffinity;
  ValueChanged<String>? onChanged;
  Key? widgetKey;
}

Widget _buildRadio(_RadioConfig config) {
  if (config.label == null || config.label!.trim().isEmpty) {
    return Radio<String>(
      key: config.widgetKey,
      value: config.value!,
      groupValue: config.groupValue,
      toggleable: config.toggleable ?? false,
      activeColor: config.activeColor,
      fillColor: config.fillColor,
      focusColor: config.focusColor,
      hoverColor: config.hoverColor,
      splashRadius: config.splashRadius,
      onChanged: config.onChanged == null
          ? null
          : (value) {
              if (value != null) {
                config.onChanged!(value);
              }
            },
    );
  }

  return RadioListTile<String>(
    key: config.widgetKey,
    value: config.value!,
    groupValue: config.groupValue,
    title: Text(config.label!),
    toggleable: config.toggleable ?? false,
    activeColor: config.activeColor,
    fillColor: config.fillColor,
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
