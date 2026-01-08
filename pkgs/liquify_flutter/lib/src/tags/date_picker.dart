import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DatePickerTag extends WidgetTagBase with AsyncTag {
  DatePickerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildDatePicker(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildDatePicker(config));
  }

  _DatePickerConfig _parseConfig(Evaluator evaluator) {
    final config = _DatePickerConfig();
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
        case 'date':
          config.value = parseDateTime(value);
          break;
        case 'firstDate':
        case 'minDate':
          config.firstDate = parseDateTime(value);
          break;
        case 'lastDate':
        case 'maxDate':
          config.lastDate = parseDateTime(value);
          break;
        case 'currentDate':
          config.currentDate = parseDateTime(value);
          break;
        case 'label':
        case 'text':
          config.label = value?.toString();
          break;
        case 'icon':
          config.icon = resolveIconWidget(value);
          break;
        case 'enabled':
          config.enabled = toBool(value);
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
        case 'errorFormatText':
          config.errorFormatText = value?.toString();
          break;
        case 'errorInvalidText':
          config.errorInvalidText = value?.toString();
          break;
        case 'fieldHintText':
          config.fieldHintText = value?.toString();
          break;
        case 'fieldLabelText':
          config.fieldLabelText = value?.toString();
          break;
        case 'initialEntryMode':
          config.initialEntryMode = _parseEntryMode(value);
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
          handleUnknownArg('date_picker', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'date_picker',
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
      tag: 'date_picker',
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

class _DatePickerConfig {
  DateTime? value;
  DateTime? firstDate;
  DateTime? lastDate;
  DateTime? currentDate;
  String? label;
  Widget? icon;
  bool? enabled;
  String? helpText;
  String? cancelText;
  String? confirmText;
  String? errorFormatText;
  String? errorInvalidText;
  String? fieldHintText;
  String? fieldLabelText;
  DatePickerEntryMode? initialEntryMode;
  ValueChanged<String>? onChanged;
  Map<String, dynamic>? event;
  Key? widgetKey;
}

Widget _buildDatePicker(_DatePickerConfig config) {
  final resolved = config.value ?? DateTime.now();
  final firstDate = config.firstDate ??
      DateTime(resolved.year - 5, 1, 1);
  final lastDate = config.lastDate ??
      DateTime(resolved.year + 5, 12, 31);
  final clamped = _clampDate(resolved, firstDate, lastDate);
  final label = config.label ?? formatDate(clamped);
  final enabled = config.enabled ?? true;

  return Builder(
    builder: (context) {
      Future<void> handlePressed() async {
        final picked = await showDatePicker(
          context: context,
          initialDate: clamped,
          firstDate: firstDate,
          lastDate: lastDate,
          currentDate: config.currentDate ?? clamped,
          helpText: config.helpText,
          cancelText: config.cancelText,
          confirmText: config.confirmText,
          errorFormatText: config.errorFormatText,
          errorInvalidText: config.errorInvalidText,
          fieldHintText: config.fieldHintText,
          fieldLabelText: config.fieldLabelText,
          initialEntryMode:
              config.initialEntryMode ?? DatePickerEntryMode.calendar,
        );
        if (picked == null || config.onChanged == null) {
          return;
        }
        final formatted = formatDate(picked);
        final event = config.event;
        if (event != null) {
          event['value'] = formatted;
          event['year'] = picked.year;
          event['month'] = picked.month;
          event['day'] = picked.day;
        }
        config.onChanged!(formatted);
      }

      return TextButton.icon(
        key: config.widgetKey,
        onPressed: enabled ? handlePressed : null,
        icon: config.icon ?? const Icon(Icons.event),
        label: Text(label),
      );
    },
  );
}

DatePickerEntryMode? _parseEntryMode(Object? value) {
  if (value is DatePickerEntryMode) {
    return value;
  }
  final text = value?.toString().toLowerCase().trim();
  switch (text) {
    case 'calendar':
      return DatePickerEntryMode.calendar;
    case 'input':
      return DatePickerEntryMode.input;
    case 'calendaronly':
    case 'calendar_only':
      return DatePickerEntryMode.calendarOnly;
    case 'inputonly':
    case 'input_only':
      return DatePickerEntryMode.inputOnly;
  }
  return null;
}

DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
  if (value.isBefore(first)) {
    return first;
  }
  if (value.isAfter(last)) {
    return last;
  }
  return value;
}
