import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ToggleButtonsTag extends WidgetTagBase with AsyncTag {
  ToggleButtonsTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildToggleButtons(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildToggleButtons(config));
  }

  _ToggleButtonsConfig _parseConfig(Evaluator evaluator) {
    final config = _ToggleButtonsConfig();
    final namedValues = <String, Object?>{};
    Object? actionValue;
    Object? onPressedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? itemsValue;
    Object? iconsValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'labels':
        case 'options':
          config.labels = parseListOfString(value);
          break;
        case 'items':
          itemsValue = value;
          break;
        case 'icons':
          iconsValue = value;
          break;
        case 'selected':
        case 'selectedIndex':
        case 'value':
          config.selectedIndex = toInt(value);
          break;
        case 'isSelected':
          config.isSelected = _parseSelectedList(value);
          break;
        case 'color':
          namedValues[name] = value;
          break;
        case 'selectedColor':
          config.selectedColor = parseColor(value);
          break;
        case 'fillColor':
          config.fillColor = parseColor(value);
          break;
        case 'borderColor':
          config.borderColor = parseColor(value);
          break;
        case 'selectedBorderColor':
          config.selectedBorderColor = parseColor(value);
          break;
        case 'borderRadius':
          final radius = parseBorderRadiusGeometry(value);
          config.borderRadius = radius is BorderRadius ? radius : null;
          break;
        case 'constraints':
          config.constraints = parseBoxConstraints(value);
          break;
        case 'borderWidth':
          config.borderWidth = toDouble(value);
          break;
        case 'direction':
          config.direction = parseAxis(value);
          break;
        case 'renderBorder':
          config.renderBorder = toBool(value);
          break;
        case 'tapTargetSize':
          config.tapTargetSize = parseMaterialTapTargetSize(value);
          break;
        case 'disabledColor':
          config.disabledColor = parseColor(value);
          break;
        case 'splashColor':
          config.splashColor = parseColor(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'focusColor':
          config.focusColor = parseColor(value);
          break;
        case 'highlightColor':
          config.highlightColor = parseColor(value);
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
          handleUnknownArg('toggle_buttons', name);
          break;
      }
    }

    config.items =
        _resolveItems(itemsValue, config.labels, iconsValue) ??
            _buildLabelItems(config.labels);
    if (config.items!.isEmpty) {
      config.items = _buildLabelItems(const ['One', 'Two', 'Three']);
    }
    if (config.items!.isNotEmpty && config.isSelected == null) {
      final selectedIndex = config.selectedIndex ?? 0;
      config.isSelected = List<bool>.generate(
        config.items!.length,
        (index) => index == selectedIndex,
      );
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'toggle_buttons',
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
      tag: 'toggle_buttons',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {
        'count': config.items!.length,
      },
    );
    final callback =
        resolveIntActionCallback(
              evaluator,
              onPressedValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveIntActionCallback(
              evaluator,
              actionValue,
              event: baseEvent,
              actionValue: actionName,
            );
    config.onPressed = callback == null
        ? null
        : (index) {
            baseEvent['index'] = index;
            if (index >= 0 && index < config.items!.length) {
              baseEvent['value'] = config.items![index].value;
            }
            callback(index);
          };
    config.color = resolvePropertyValue<Color?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'color',
          parser: parseColor,
        ) ??
        config.color;
    return config;
  }
}

class _ToggleButtonsConfig {
  List<String>? labels;
  List<_ToggleItem>? items;
  int? selectedIndex;
  List<bool>? isSelected;
  Color? color;
  Color? selectedColor;
  Color? fillColor;
  Color? borderColor;
  Color? selectedBorderColor;
  BorderRadius? borderRadius;
  BoxConstraints? constraints;
  double? borderWidth;
  Axis? direction;
  bool? renderBorder;
  MaterialTapTargetSize? tapTargetSize;
  Color? disabledColor;
  Color? splashColor;
  Color? hoverColor;
  Color? focusColor;
  Color? highlightColor;
  ValueChanged<int>? onPressed;
  Key? widgetKey;
}

Widget _buildToggleButtons(_ToggleButtonsConfig config) {
  final items = config.items ?? const [];
  if (items.isEmpty || config.isSelected == null) {
    return const SizedBox.shrink();
  }
  final children = items.map((item) => item.buildChild()).toList();
  return ToggleButtons(
    key: config.widgetKey,
    isSelected: config.isSelected!,
    onPressed: config.onPressed,
    color: config.color,
    selectedColor: config.selectedColor,
    fillColor: config.fillColor,
    borderColor: config.borderColor,
    selectedBorderColor: config.selectedBorderColor,
    borderRadius: config.borderRadius,
    constraints: config.constraints,
    borderWidth: config.borderWidth,
    direction: config.direction ?? Axis.horizontal,
    renderBorder: config.renderBorder ?? true,
    tapTargetSize: config.tapTargetSize,
    disabledColor: config.disabledColor,
    splashColor: config.splashColor,
    hoverColor: config.hoverColor,
    focusColor: config.focusColor,
    highlightColor: config.highlightColor,
    children: children,
  );
}

class _ToggleItem {
  _ToggleItem({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final Widget? icon;

  Widget buildChild() {
    if (icon == null) {
      return Text(label);
    }
    if (label.trim().isEmpty) {
      return icon!;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

List<bool>? _parseSelectedList(Object? value) {
  if (value is List<bool>) {
    return value;
  }
  if (value is Iterable) {
    final values = <bool>[];
    for (final entry in value) {
      final parsed = toBool(entry);
      if (parsed == null) {
        return null;
      }
      values.add(parsed);
    }
    return values;
  }
  return null;
}

List<_ToggleItem>? _resolveItems(
  Object? itemsValue,
  List<String>? labels,
  Object? iconsValue,
) {
  if (itemsValue != null) {
    return _parseItems(itemsValue);
  }
  final icons = _parseIconItems(iconsValue);
  if (icons != null) {
    final values = labels ?? const [];
    return List<_ToggleItem>.generate(icons.length, (index) {
      final label = index < values.length ? values[index] : '';
      final value = label.isNotEmpty ? label : 'item_$index';
      return _ToggleItem(
        label: label,
        value: value,
        icon: icons[index],
      );
    });
  }
  return null;
}

List<_ToggleItem> _buildLabelItems(List<String>? labels) {
  final values = labels ?? const [];
  return values
      .map((label) => _ToggleItem(label: label, value: label))
      .toList();
}

List<_ToggleItem> _parseItems(Object? value) {
  final items = <_ToggleItem>[];
  if (value is Iterable) {
    for (final entry in value) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        final label =
            map['label'] ?? map['text'] ?? map['title'] ?? map['value'] ?? '';
        final value = map['value'] ?? label;
        items.add(
          _ToggleItem(
            label: label.toString(),
            value: value.toString(),
            icon: resolveIconWidget(map['icon']),
          ),
        );
        continue;
      }
      if (entry is IconData || entry is Icon || entry is Widget) {
        items.add(
          _ToggleItem(
            label: '',
            value: entry.toString(),
            icon: resolveIconWidget(entry),
          ),
        );
        continue;
      }
      items.add(
        _ToggleItem(
          label: entry?.toString() ?? '',
          value: entry?.toString() ?? '',
        ),
      );
    }
  }
  return items;
}

List<Widget?>? _parseIconItems(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Iterable) {
    return value.map(resolveIconWidget).toList();
  }
  return [resolveIconWidget(value)];
}
