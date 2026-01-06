import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TimePickerTag extends WidgetTagBase with AsyncTag {
  TimePickerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildTimePicker(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildTimePicker(config));
  }

  _TimePickerConfig _parseConfig(Evaluator evaluator) {
    final config = _TimePickerConfig();
    Object? actionValue;
    Object? onChangedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'value':
        case 'selected':
        case 'time':
          config.value = parseTimeOfDay(value);
          break;
        case 'label':
        case 'text':
          config.label = value?.toString();
          break;
        case 'use24Hour':
        case 'use24Hours':
        case 'is24Hour':
          config.use24Hour = toBool(value);
          break;
        case 'entryMode':
          config.entryMode = _parseEntryMode(value);
          break;
        case 'initialEntryMode':
          config.entryMode = _parseEntryMode(value);
          break;
        case 'helpText':
          config.helpText = value?.toString();
          break;
        case 'cancelText':
          config.cancelText = value?.toString();
          break;
        case 'confirmText':
          config.confirmText = value?.toString();
          break;
        case 'errorInvalidText':
          config.errorInvalidText = value?.toString();
          break;
        case 'icon':
          config.icon = resolveIconWidget(value);
          break;
        case 'enabled':
          config.enabled = toBool(value);
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
          handleUnknownArg('time_picker', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'time_picker',
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
      tag: 'time_picker',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
    );
    config.event = baseEvent;
    config.onChanged =
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
    return config;
  }
}

class _TimePickerConfig {
  TimeOfDay? value;
  String? label;
  bool? use24Hour;
  TimePickerEntryMode? entryMode;
  Widget? icon;
  bool? enabled;
  String? helpText;
  String? cancelText;
  String? confirmText;
  String? errorInvalidText;
  ValueChanged<String>? onChanged;
  Map<String, dynamic>? event;
  Key? widgetKey;
}

Widget _buildTimePicker(_TimePickerConfig config) {
  final resolved = config.value ?? const TimeOfDay(hour: 9, minute: 0);
  final label = config.label ?? formatTimeOfDay(resolved);
  final enabled = config.enabled ?? true;

  return Builder(
    builder: (context) {
      Future<void> handlePressed() async {
        final picked = await showTimePicker(
          context: context,
          initialTime: resolved,
          initialEntryMode: config.entryMode ?? TimePickerEntryMode.dial,
          helpText: config.helpText,
          cancelText: config.cancelText,
          confirmText: config.confirmText,
          errorInvalidText: config.errorInvalidText,
          builder: config.use24Hour == true
              ? (context, child) {
                  if (child == null) {
                    return const SizedBox.shrink();
                  }
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: true),
                    child: child,
                  );
                }
              : null,
        );
        if (picked == null || config.onChanged == null) {
          return;
        }
        final formatted = formatTimeOfDay(picked);
        final event = config.event;
        if (event != null) {
          event['value'] = formatted;
          event['hour'] = picked.hour;
          event['minute'] = picked.minute;
        }
        config.onChanged!(formatted);
      }

      return TextButton.icon(
        key: config.widgetKey,
        onPressed: enabled ? handlePressed : null,
        icon: config.icon ?? const Icon(Icons.schedule),
        label: Text(label),
      );
    },
  );
}

TimePickerEntryMode? _parseEntryMode(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().toLowerCase().trim();
  switch (text) {
    case 'dial':
      return TimePickerEntryMode.dial;
    case 'input':
      return TimePickerEntryMode.input;
    case 'dialonly':
    case 'dial_only':
      return TimePickerEntryMode.dialOnly;
    case 'inputonly':
    case 'input_only':
      return TimePickerEntryMode.inputOnly;
    default:
      return null;
  }
}
