// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class RadioListTileTag extends WidgetTagBase with AsyncTag {
  RadioListTileTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildRadioListTile(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildRadioListTile(config));
  }

  _RadioListTileConfig _parseConfig(Evaluator evaluator) {
    final config = _RadioListTileConfig();
    Object? actionValue;
    Object? onChangedValue;
    Object? onFocusChangeValue;
    String? widgetIdValue;
    String? widgetKeyValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'value':
          config.value = value?.toString();
          break;
        case 'groupValue':
          config.groupValue = value?.toString();
          break;
        case 'title':
          config.titleLabel = _stringValue(value);
          config.title = resolveTextWidget(value);
          break;
        case 'subtitle':
          config.subtitleLabel = _stringValue(value);
          config.subtitle = resolveTextWidget(value);
          break;
        case 'secondary':
          config.secondary = resolveIconWidget(value);
          break;
        case 'isThreeLine':
          config.isThreeLine = toBool(value);
          break;
        case 'dense':
          config.dense = toBool(value);
          break;
        case 'enabled':
          config.enabled = toBool(value);
          break;
        case 'selected':
          config.selected = toBool(value);
          break;
        case 'contentPadding':
          config.contentPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'tileColor':
          config.tileColor = parseColor(value);
          break;
        case 'selectedTileColor':
          config.selectedTileColor = parseColor(value);
          break;
        case 'controlAffinity':
          config.controlAffinity = parseListTileControlAffinity(value);
          break;
        case 'activeColor':
          config.activeColor = parseColor(value);
          break;
        case 'fillColor':
          config.fillColor = toWidgetStateColor(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'mouseCursor':
          if (value is MouseCursor) {
            config.mouseCursor = value;
          }
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'onFocusChange':
          onFocusChangeValue = value;
          break;
        case 'splashRadius':
          config.splashRadius = toDouble(value);
          break;
        case 'materialTapTargetSize':
          config.materialTapTargetSize = parseMaterialTapTargetSize(value);
          break;
        case 'visualDensity':
          config.visualDensity = parseVisualDensity(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'toggleable':
          config.toggleable = toBool(value);
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
          handleUnknownArg('radio_list_tile', name);
          break;
      }
    }

    if (config.value == null || config.value!.trim().isEmpty) {
      throw Exception('radio_list_tile tag requires "value"');
    }

    final ids = resolveIds(
      evaluator,
      'radio_list_tile',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'radio_list_tile',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'changed',
      props: {
        'title': config.titleLabel,
        'subtitle': config.subtitleLabel,
        'groupValue': config.groupValue,
      },
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
    if (callback != null) {
      config.onChanged = (value) {
        baseEvent['value'] = value;
        callback(value);
      };
    }
    config.onFocusChange = resolveBoolActionCallback(
      evaluator,
      onFocusChangeValue,
    );
    return config;
  }
}

class _RadioListTileConfig {
  String? value;
  String? groupValue;
  Widget? title;
  String? titleLabel;
  Widget? subtitle;
  String? subtitleLabel;
  Widget? secondary;
  bool? isThreeLine;
  bool? dense;
  bool? enabled;
  bool? selected;
  EdgeInsetsGeometry? contentPadding;
  ListTileControlAffinity? controlAffinity;
  Color? activeColor;
  WidgetStateProperty<Color?>? fillColor;
  ShapeBorder? shape;
  Color? tileColor;
  Color? selectedTileColor;
  Color? hoverColor;
  double? splashRadius;
  MaterialTapTargetSize? materialTapTargetSize;
  VisualDensity? visualDensity;
  MouseCursor? mouseCursor;
  bool? autofocus;
  ValueChanged<bool>? onFocusChange;
  bool? enableFeedback;
  bool? toggleable;
  ValueChanged<String>? onChanged;
  Key? widgetKey;
}

Widget _buildRadioListTile(_RadioListTileConfig config) {
  return RadioListTile<String>(
    key: config.widgetKey,
    value: config.value!,
    groupValue: config.groupValue,
    onChanged: config.onChanged == null
        ? null
        : (value) {
            if (value != null) {
              config.onChanged!(value);
            }
          },
    title: config.title,
    subtitle: config.subtitle,
    secondary: config.secondary,
    isThreeLine: config.isThreeLine ?? false,
    dense: config.dense,
    enabled: config.enabled,
    contentPadding: config.contentPadding,
    controlAffinity: config.controlAffinity,
    activeColor: config.activeColor,
    fillColor: config.fillColor,
    shape: config.shape,
    tileColor: config.tileColor,
    selectedTileColor: config.selectedTileColor,
    hoverColor: config.hoverColor,
    splashRadius: config.splashRadius,
    materialTapTargetSize: config.materialTapTargetSize,
    visualDensity: config.visualDensity,
    mouseCursor: config.mouseCursor,
    autofocus: config.autofocus ?? false,
    onFocusChange: config.onFocusChange,
    enableFeedback: config.enableFeedback,
    selected: config.selected ?? false,
    toggleable: config.toggleable ?? false,
  );
}

String? _stringValue(Object? value) {
  if (value == null || value is Widget) {
    return null;
  }
  return value.toString();
}
