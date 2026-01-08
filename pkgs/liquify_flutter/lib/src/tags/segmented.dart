import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SegmentedControlTag extends WidgetTagBase with AsyncTag {
  SegmentedControlTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSegmented(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSegmented(config));
  }

  _SegmentedConfig _parseConfig(Evaluator evaluator) {
    final config = _SegmentedConfig();
    Object? actionValue;
    Object? onChangedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? selectedValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'labels':
        case 'items':
        case 'options':
          config.labels = parseListOfString(value);
          break;
        case 'selected':
          selectedValue = value;
          break;
        case 'selectedIndex':
        case 'value':
          config.selectedIndex = toInt(value);
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
        case 'selectedIcon':
          config.selectedIcon = resolveIconWidget(value);
          break;
        case 'showSelectedIcon':
          config.showSelectedIcon = toBool(value);
          break;
        case 'style':
          if (value is ButtonStyle) {
            config.style = value;
          }
          break;
        case 'multiSelectionEnabled':
          config.multiSelectionEnabled = toBool(value);
          break;
        case 'emptySelectionAllowed':
          config.emptySelectionAllowed = toBool(value);
          break;
        case 'direction':
          config.direction = parseAxis(value);
          break;
        default:
          handleUnknownArg('segmented', name);
          break;
      }
    }
    config.labels ??= const [];
    if (selectedValue != null) {
      config.selected = _parseSelectedSet(selectedValue);
    }
    if (config.labels!.isNotEmpty &&
        config.selected == null &&
        config.selectedIndex == null) {
      config.selectedIndex = 0;
    }
    if (config.selected == null && config.selectedIndex != null) {
      config.selected = {config.selectedIndex!};
    }
    if (config.selected != null &&
        config.selected!.isEmpty &&
        config.emptySelectionAllowed != true &&
        config.labels!.isNotEmpty) {
      config.selected = {0};
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'segmented',
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
      tag: 'segmented',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {
        'count': config.labels!.length,
      },
    );
    final callback =
        resolveIntSetActionCallback(
              evaluator,
              onChangedValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveIntSetActionCallback(
              evaluator,
              actionValue,
              event: baseEvent,
              actionValue: actionName,
            );
    config.onChanged = callback == null
        ? null
        : (selection) {
            final selectedList = selection.toList()..sort();
            baseEvent['selection'] = selectedList;
            if (selectedList.isNotEmpty) {
              final index = selectedList.first;
              baseEvent['index'] = index;
              if (index >= 0 && index < config.labels!.length) {
                baseEvent['value'] = config.labels![index];
              }
            }
            callback(selection);
          };
    return config;
  }
}

class _SegmentedConfig {
  List<String>? labels;
  int? selectedIndex;
  Set<int>? selected;
  ValueChanged<Set<int>>? onChanged;
  Widget? selectedIcon;
  bool? showSelectedIcon;
  ButtonStyle? style;
  bool? multiSelectionEnabled;
  bool? emptySelectionAllowed;
  Axis? direction;
  Key? widgetKey;
}

Widget _buildSegmented(_SegmentedConfig config) {
  final labels = config.labels ?? const [];
  if (labels.isEmpty) {
    return const SizedBox.shrink();
  }
  final selected = config.selected ?? const {0};
  final segments = <ButtonSegment<int>>[];
  for (var i = 0; i < labels.length; i++) {
    segments.add(
      ButtonSegment<int>(
        value: i,
        label: Text(labels[i]),
      ),
    );
  }
  return SegmentedButton<int>(
    key: config.widgetKey,
    segments: segments,
    selected: selected,
    onSelectionChanged: config.onChanged == null
        ? null
        : (selection) {
            config.onChanged!(selection);
          },
    selectedIcon: config.selectedIcon,
    showSelectedIcon: config.showSelectedIcon ?? true,
    style: config.style,
    multiSelectionEnabled: config.multiSelectionEnabled ?? false,
    emptySelectionAllowed: config.emptySelectionAllowed ?? false,
    direction: config.direction ?? Axis.horizontal,
  );
}

Set<int>? _parseSelectedSet(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Set<int>) {
    return value;
  }
  if (value is Iterable) {
    final values = <int>{};
    for (final entry in value) {
      final parsed = toInt(entry);
      if (parsed != null) {
        values.add(parsed);
      }
    }
    return values;
  }
  final parsed = toInt(value);
  if (parsed == null) {
    return null;
  }
  return {parsed};
}
