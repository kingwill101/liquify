import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TimePickerDialogTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TimePickerDialogTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildDialog(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildDialog(config));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('time_picker_dialog').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endtime_picker_dialog').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'time_picker_dialog',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _TimePickerDialogConfig _parseConfig(Evaluator evaluator) {
    final config = _TimePickerDialogConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'cancelText':
          config.cancelText = toStringValue(value);
          break;
        case 'confirmText':
          config.confirmText = toStringValue(value);
          break;
        case 'emptyInitialInput':
          config.emptyInitialInput = toBool(value);
          break;
        case 'errorInvalidText':
          config.errorInvalidText = toStringValue(value);
          break;
        case 'helpText':
          config.helpText = toStringValue(value);
          break;
        case 'hourLabelText':
          config.hourLabelText = toStringValue(value);
          break;
        case 'initialEntryMode':
          config.initialEntryMode = parseTimePickerEntryMode(value);
          break;
        case 'initialTime':
          config.initialTime = parseTimeOfDay(value);
          break;
        case 'key':
          config.key = parseKey(evaluator, value);
          break;
        case 'minuteLabelText':
          config.minuteLabelText = toStringValue(value);
          break;
        case 'onEntryModeChanged':
          config.onEntryModeChanged = resolveGenericValueChanged(
            evaluator,
            value,
          );
          break;
        case 'orientation':
          config.orientation = parseOrientation(value);
          break;
        case 'restorationId':
          config.restorationId = toStringValue(value);
          break;
        case 'switchToInputEntryModeIcon':
          config.switchToInputEntryModeIcon = parseIcon(evaluator, value);
          break;
        case 'switchToTimerEntryModeIcon':
          config.switchToTimerEntryModeIcon = parseIcon(evaluator, value);
          break;
        default:
          handleUnknownArg('time_picker_dialog', name);
          break;
      }
    }
    return config;
  }
}

class _TimePickerDialogConfig {
  String? cancelText;
  String? confirmText;
  bool? emptyInitialInput;
  String? errorInvalidText;
  String? helpText;
  String? hourLabelText;
  TimePickerEntryMode? initialEntryMode;
  TimeOfDay? initialTime;
  Key? key;
  String? minuteLabelText;
  ValueChanged<dynamic>? onEntryModeChanged;
  Orientation? orientation;
  String? restorationId;
  Icon? switchToInputEntryModeIcon;
  Icon? switchToTimerEntryModeIcon;
}

TimePickerDialog _buildDialog(_TimePickerDialogConfig config) {
  return TimePickerDialog(
    cancelText: config.cancelText,
    confirmText: config.confirmText,
    emptyInitialInput: config.emptyInitialInput ?? false,
    errorInvalidText: config.errorInvalidText,
    helpText: config.helpText,
    hourLabelText: config.hourLabelText,
    initialEntryMode: config.initialEntryMode ?? TimePickerEntryMode.dial,
    initialTime: config.initialTime ?? const TimeOfDay(hour: 9, minute: 0),
    key: config.key,
    minuteLabelText: config.minuteLabelText,
    onEntryModeChanged: config.onEntryModeChanged,
    orientation: config.orientation,
    restorationId: config.restorationId,
    switchToInputEntryModeIcon: config.switchToInputEntryModeIcon,
    switchToTimerEntryModeIcon: config.switchToTimerEntryModeIcon,
  );
}
