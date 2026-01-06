import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DropdownTag extends WidgetTagBase with AsyncTag {
  DropdownTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    config.alignment = resolvePropertyValue<AlignmentGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'alignment',
      parser: parseAlignmentGeometry,
    );
    buffer.write(_buildDropdown(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    config.alignment = resolvePropertyValue<AlignmentGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'alignment',
      parser: parseAlignmentGeometry,
    );
    buffer.write(_buildDropdown(config));
  }

  _DropdownConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _DropdownConfig();
    Object? actionValue;
    Object? onChangedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'items':
        case 'options':
          config.items = _parseItems(value);
          break;
        case 'value':
        case 'selected':
        case 'selectedValue':
          config.value = value?.toString();
          break;
        case 'hint':
        case 'placeholder':
          config.hint = value?.toString();
          break;
        case 'isExpanded':
        case 'expanded':
          config.isExpanded = toBool(value);
          break;
        case 'icon':
          config.icon = resolveIconWidget(value);
          break;
        case 'iconSize':
          config.iconSize = toDouble(value);
          break;
        case 'elevation':
          config.elevation = toInt(value);
          break;
        case 'borderRadius':
          final radius = parseBorderRadiusGeometry(value);
          config.borderRadius = radius is BorderRadius ? radius : null;
          break;
        case 'menuMaxHeight':
          config.menuMaxHeight = toDouble(value);
          break;
        case 'dropdownColor':
          config.dropdownColor = parseColor(value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'alignment':
          namedValues[name] = value;
          break;
        case 'style':
          config.style = parseTextStyle(value) ?? config.style;
          break;
        case 'iconEnabledColor':
          config.iconEnabledColor = parseColor(value);
          break;
        case 'iconDisabledColor':
          config.iconDisabledColor = parseColor(value);
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
          handleUnknownArg('dropdown', name);
          break;
      }
    }

    config.items ??= const [];
    final resolvedId = resolveWidgetId(
      evaluator,
      'dropdown',
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
      tag: 'dropdown',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: {'count': config.items!.length},
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

class _DropdownConfig {
  List<_DropdownItem>? items;
  String? value;
  String? hint;
  bool? isExpanded;
  bool? enabled;
  Widget? icon;
  double? iconSize;
  int? elevation;
  BorderRadius? borderRadius;
  double? menuMaxHeight;
  Color? dropdownColor;
  EdgeInsetsGeometry? padding;
  bool? enableFeedback;
  AlignmentGeometry? alignment;
  TextStyle? style;
  Color? iconEnabledColor;
  Color? iconDisabledColor;
  ValueChanged<String>? onChanged;
  Key? widgetKey;
}

class _DropdownItem {
  _DropdownItem({required this.label, required this.value, this.icon});

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
      children: [icon!, const SizedBox(width: 8), Text(label)],
    );
  }
}

Widget _buildDropdown(_DropdownConfig config) {
  final items = config.items ?? const [];
  if (items.isEmpty) {
    return const SizedBox.shrink();
  }
  final enabled = config.enabled ?? true;
  final selectedValue = items.any((item) => item.value == config.value)
      ? config.value
      : null;
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final defaultStyle =
          theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ) ??
          TextStyle(color: theme.colorScheme.onSurface);
      return DropdownButton<String>(
        key: config.widgetKey,
        isExpanded: config.isExpanded ?? false,
        value: selectedValue,
        hint: config.hint == null ? null : Text(config.hint!),
        icon: config.icon,
        iconSize: config.iconSize ?? 24,
        elevation: config.elevation ?? 8,
        borderRadius: config.borderRadius,
        menuMaxHeight: config.menuMaxHeight,
        dropdownColor: config.dropdownColor,
        padding: config.padding,
        enableFeedback: config.enableFeedback,
        alignment: config.alignment ?? AlignmentDirectional.centerStart,
        iconEnabledColor: config.iconEnabledColor,
        iconDisabledColor: config.iconDisabledColor,
        style: config.style ?? defaultStyle,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item.value,
                child: item.buildChild(),
              ),
            )
            .toList(),
        onChanged: (!enabled || config.onChanged == null)
            ? null
            : (value) {
                if (value == null) {
                  return;
                }
                config.onChanged!(value);
              },
      );
    },
  );
}

List<_DropdownItem> _parseItems(Object? value) {
  final items = <_DropdownItem>[];
  if (value is Map) {
    value.forEach((key, entry) {
      final label = entry?.toString() ?? key.toString();
      items.add(_DropdownItem(label: label, value: key.toString()));
    });
    return items;
  }
  if (value is Iterable) {
    for (final entry in value) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        final label =
            map['label'] ?? map['text'] ?? map['title'] ?? map['value'];
        final value = map['value'] ?? label;
        items.add(
          _DropdownItem(
            label: label?.toString() ?? '',
            value: value?.toString() ?? '',
            icon: resolveIconWidget(map['icon']),
          ),
        );
        continue;
      }
      items.add(
        _DropdownItem(
          label: entry?.toString() ?? '',
          value: entry?.toString() ?? '',
        ),
      );
    }
    return items;
  }
  if (value == null) {
    return items;
  }
  items.add(_DropdownItem(label: value.toString(), value: value.toString()));
  return items;
}
