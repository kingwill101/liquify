import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliderTag extends WidgetTagBase with AsyncTag {
  SliderTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSlider(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSlider(config));
  }

  _SliderConfig _parseConfig(Evaluator evaluator) {
    final config = _SliderConfig();
    Object? actionValue;
    Object? onChangedValue;
    Object? onChangeStartValue;
    Object? onChangeEndValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'value':
          config.value = toDouble(value);
          break;
        case 'min':
          config.min = toDouble(value);
          break;
        case 'max':
          config.max = toDouble(value);
          break;
        case 'divisions':
          config.divisions = toInt(value);
          break;
        case 'label':
          config.label = value?.toString();
          break;
        case 'activeColor':
          config.activeColor = parseColor(value);
          break;
        case 'inactiveColor':
          config.inactiveColor = parseColor(value);
          break;
        case 'thumbColor':
          config.thumbColor = parseColor(value);
          break;
        case 'secondaryTrackValue':
          config.secondaryTrackValue = toDouble(value);
          break;
        case 'mouseCursor':
          config.mouseCursor = parseMouseCursor(value);
          break;
        case 'focusNode':
          if (value is FocusNode) {
            config.focusNode = value;
          }
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'semanticFormatterCallback':
          config.semanticFormatterCallback =
              parseSliderSemanticFormatter(evaluator, value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onChanged':
          onChangedValue = value;
          break;
        case 'onChangeStart':
          onChangeStartValue = value;
          break;
        case 'onChangeEnd':
          onChangeEndValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('slider', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'slider',
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
      tag: 'slider',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {
        'min': config.min,
        'max': config.max,
      },
    );
    final callback =
        resolveDoubleActionCallback(
              evaluator,
              onChangedValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveDoubleActionCallback(
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

    final startEvent = {
      ...baseEvent,
      'event': 'start',
    };
    final startCallback =
        resolveDoubleActionCallback(
              evaluator,
              onChangeStartValue,
              event: startEvent,
              actionValue: actionName,
            ) ??
            resolveDoubleActionCallback(
              evaluator,
              actionValue,
              event: startEvent,
              actionValue: actionName,
            );
    config.onChangeStart = startCallback == null
        ? null
        : (value) {
            startEvent['value'] = value;
            startCallback(value);
          };

    final endEvent = {
      ...baseEvent,
      'event': 'end',
    };
    final endCallback =
        resolveDoubleActionCallback(
              evaluator,
              onChangeEndValue,
              event: endEvent,
              actionValue: actionName,
            ) ??
            resolveDoubleActionCallback(
              evaluator,
              actionValue,
              event: endEvent,
              actionValue: actionName,
            );
    config.onChangeEnd = endCallback == null
        ? null
        : (value) {
            endEvent['value'] = value;
            endCallback(value);
          };
    return config;
  }
}

class _SliderConfig {
  double? value;
  double? min;
  double? max;
  int? divisions;
  String? label;
  Color? activeColor;
  Color? inactiveColor;
  Color? thumbColor;
  double? secondaryTrackValue;
  ValueChanged<double>? onChanged;
  ValueChanged<double>? onChangeStart;
  ValueChanged<double>? onChangeEnd;
  MouseCursor? mouseCursor;
  FocusNode? focusNode;
  bool? autofocus;
  SemanticFormatterCallback? semanticFormatterCallback;
  Key? widgetKey;
}

Widget _buildSlider(_SliderConfig config) {
  if (config.value == null) {
    throw Exception('slider tag requires "value"');
  }
  final min = config.min ?? 0;
  final max = config.max ?? 1;
  final clamped = config.value!.clamp(min, max).toDouble();
  return Slider(
    key: config.widgetKey,
    value: clamped,
    min: min,
    max: max,
    divisions: config.divisions,
    label: config.label,
    activeColor: config.activeColor,
    inactiveColor: config.inactiveColor,
    thumbColor: config.thumbColor,
    secondaryTrackValue: config.secondaryTrackValue,
    onChanged: config.onChanged,
    onChangeStart: config.onChangeStart,
    onChangeEnd: config.onChangeEnd,
    mouseCursor: config.mouseCursor,
    focusNode: config.focusNode,
    autofocus: config.autofocus ?? false,
    semanticFormatterCallback: config.semanticFormatterCallback,
  );
}
