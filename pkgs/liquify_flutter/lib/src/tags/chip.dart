import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

enum ChipVariant { chip, action, choice, filter, input }

class ChipTag extends WidgetTagBase with AsyncTag {
  ChipTag(this.tagName, this._variant, super.content, super.filters);

  ChipTag.chip(super.content, super.filters)
      : tagName = 'chip',
        _variant = ChipVariant.chip;

  ChipTag.action(super.content, super.filters)
      : tagName = 'action_chip',
        _variant = ChipVariant.action;

  ChipTag.choice(super.content, super.filters)
      : tagName = 'choice_chip',
        _variant = ChipVariant.choice;

  ChipTag.filter(super.content, super.filters)
      : tagName = 'filter_chip',
        _variant = ChipVariant.filter;

  ChipTag.input(super.content, super.filters)
      : tagName = 'input_chip',
        _variant = ChipVariant.input;

  final String tagName;
  final ChipVariant _variant;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildChip(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildChip(config));
  }

  _ChipConfig _parseConfig(Evaluator evaluator) {
    final config = _ChipConfig();
    final namedValues = <String, Object?>{};
    Object? actionValue;
    Object? selectActionValue;
    Object? deleteActionValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
        case 'text':
        case 'title':
          config.label = value?.toString();
          break;
        case 'value':
          config.value = value;
          break;
        case 'selected':
        case 'isSelected':
          config.selected = toBool(value);
          break;
        case 'enabled':
          config.enabled = toBool(value);
          break;
        case 'avatar':
          config.avatar = _resolveChipAvatar(value, asIcon: false);
          break;
        case 'icon':
          config.avatar = _resolveChipAvatar(value, asIcon: true);
          break;
        case 'backgroundColor':
        case 'background':
          config.backgroundColor = parseColor(value);
          break;
        case 'selectedColor':
          config.selectedColor = parseColor(value);
          break;
        case 'disabledColor':
          config.disabledColor = parseColor(value);
          break;
        case 'checkmarkColor':
          config.checkmarkColor = parseColor(value);
          break;
        case 'showCheckmark':
          config.showCheckmark = toBool(value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'radius':
          config.radius = toDouble(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'labelStyle':
          config.labelStyle = parseTextStyle(value);
          break;
        case 'shape':
          final shape = parseShapeBorder(value);
          if (shape is OutlinedBorder) {
            config.shape = shape;
          }
          break;
        case 'side':
          config.side = parseBorderSide(value);
          break;
        case 'visualDensity':
          config.visualDensity = parseVisualDensity(value);
          break;
        case 'materialTapTargetSize':
          config.materialTapTargetSize = parseMaterialTapTargetSize(value);
          break;
        case 'clipBehavior':
        case 'clip':
          config.clipBehavior = parseClip(value);
          break;
        case 'deleteIcon':
          config.deleteIcon = resolveIconWidget(value);
          break;
        case 'deleteIconColor':
          config.deleteIconColor = parseColor(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'selectAction':
        case 'onSelected':
          selectActionValue = value;
          break;
        case 'deleteAction':
          deleteActionValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }

    if (config.label == null || config.label!.trim().isEmpty) {
      throw Exception('$tagName tag requires "label"');
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      tagName,
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final resolvedKeyValue =
        (widgetKeyValue != null && widgetKeyValue.trim().isNotEmpty)
            ? widgetKeyValue.trim()
            : resolvedId;
    config.widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = actionValue is String ? actionValue : null;
    final selectActionName =
        selectActionValue is String ? selectActionValue : null;
    final deleteActionName =
        deleteActionValue is String ? deleteActionValue : null;

    final baseEvent = buildWidgetEvent(
      tag: tagName,
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'pressed',
      props: {
        'label': config.label,
        'value': config.value ?? config.label,
      },
    );
    config.onPressed = resolveActionCallback(
      evaluator,
      actionValue,
      event: baseEvent,
      actionValue: actionName,
    );

    final selectionEvent = buildWidgetEvent(
      tag: tagName,
      id: resolvedId,
      key: resolvedKeyValue,
      action: selectActionName ?? actionName,
      event: 'changed',
      props: {
        'label': config.label,
        'value': config.value ?? config.label,
      },
    );
    final selectionCallback =
        resolveBoolActionCallback(
              evaluator,
              selectActionValue,
              event: selectionEvent,
              actionValue: selectActionName,
            ) ??
            resolveBoolActionCallback(
              evaluator,
              actionValue,
              event: selectionEvent,
              actionValue: actionName,
            );
    config.onSelected = selectionCallback == null
        ? null
        : (selected) {
            selectionEvent['selected'] = selected;
            selectionEvent['value'] = config.value ?? config.label;
            selectionCallback(selected);
          };

    final deleteEvent = buildWidgetEvent(
      tag: tagName,
      id: resolvedId,
      key: resolvedKeyValue,
      action: deleteActionName,
      event: 'deleted',
      props: {
        'label': config.label,
        'value': config.value ?? config.label,
      },
    );
    config.onDeleted = resolveActionCallback(
      evaluator,
      deleteActionValue,
      event: deleteEvent,
      actionValue: deleteActionName,
    );
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    return config;
  }

  Widget _buildChip(_ChipConfig config) {
    final label = Text(config.label!, style: config.labelStyle);
    OutlinedBorder? shape = config.shape;
    if (shape == null && config.radius != null) {
      shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(config.radius!),
        side: config.side ?? BorderSide.none,
      );
    } else if (shape is OutlinedBorder && config.side != null) {
      shape = shape.copyWith(side: config.side);
    } else if (shape == null && config.side != null) {
      shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: config.side!,
      );
    }
    final enabled = config.enabled ?? true;

    switch (_variant) {
      case ChipVariant.chip:
        return Chip(
          key: config.widgetKey,
          label: label,
          avatar: config.avatar,
          backgroundColor: config.backgroundColor,
          padding: config.padding,
          shape: shape,
          elevation: config.elevation,
          labelStyle: config.labelStyle,
          visualDensity: config.visualDensity,
          materialTapTargetSize: config.materialTapTargetSize,
          clipBehavior: config.clipBehavior ?? Clip.none,
          deleteIcon: config.deleteIcon,
          deleteIconColor: config.deleteIconColor,
          onDeleted: enabled ? config.onDeleted : null,
        );
      case ChipVariant.action:
        return ActionChip(
          key: config.widgetKey,
          label: label,
          avatar: config.avatar,
          backgroundColor: config.backgroundColor,
          padding: config.padding,
          shape: shape,
          elevation: config.elevation,
          labelStyle: config.labelStyle,
          visualDensity: config.visualDensity,
          materialTapTargetSize: config.materialTapTargetSize,
          clipBehavior: config.clipBehavior ?? Clip.none,
          onPressed: enabled ? config.onPressed : null,
        );
      case ChipVariant.choice:
        return ChoiceChip(
          key: config.widgetKey,
          label: label,
          avatar: config.avatar,
          selected: config.selected ?? false,
          onSelected: enabled ? config.onSelected : null,
          backgroundColor: config.backgroundColor,
          selectedColor: config.selectedColor,
          disabledColor: config.disabledColor,
          checkmarkColor: config.checkmarkColor,
          showCheckmark: config.showCheckmark,
          padding: config.padding,
          shape: shape,
          elevation: config.elevation,
          labelStyle: config.labelStyle,
          visualDensity: config.visualDensity,
          materialTapTargetSize: config.materialTapTargetSize,
          clipBehavior: config.clipBehavior ?? Clip.none,
        );
      case ChipVariant.filter:
        return FilterChip(
          key: config.widgetKey,
          label: label,
          avatar: config.avatar,
          selected: config.selected ?? false,
          onSelected: enabled ? config.onSelected : null,
          backgroundColor: config.backgroundColor,
          selectedColor: config.selectedColor,
          disabledColor: config.disabledColor,
          checkmarkColor: config.checkmarkColor,
          showCheckmark: config.showCheckmark,
          padding: config.padding,
          shape: shape,
          labelStyle: config.labelStyle,
          visualDensity: config.visualDensity,
          materialTapTargetSize: config.materialTapTargetSize,
          clipBehavior: config.clipBehavior ?? Clip.none,
        );
      case ChipVariant.input:
        return InputChip(
          key: config.widgetKey,
          label: label,
          avatar: config.avatar,
          selected: config.selected ?? false,
          onSelected: enabled ? config.onSelected : null,
          onPressed: enabled ? config.onPressed : null,
          onDeleted: enabled ? config.onDeleted : null,
          backgroundColor: config.backgroundColor,
          selectedColor: config.selectedColor,
          disabledColor: config.disabledColor,
          checkmarkColor: config.checkmarkColor,
          showCheckmark: config.showCheckmark,
          padding: config.padding,
          shape: shape,
          labelStyle: config.labelStyle,
          visualDensity: config.visualDensity,
          materialTapTargetSize: config.materialTapTargetSize,
          clipBehavior: config.clipBehavior ?? Clip.none,
          deleteIcon: config.deleteIcon,
          deleteIconColor: config.deleteIconColor,
        );
    }
  }
}

class _ChipConfig {
  String? label;
  Object? value;
  bool? selected;
  bool? enabled;
  Widget? avatar;
  Color? backgroundColor;
  Color? selectedColor;
  Color? disabledColor;
  Color? checkmarkColor;
  bool? showCheckmark;
  EdgeInsetsGeometry? padding;
  double? radius;
  double? elevation;
  TextStyle? labelStyle;
  OutlinedBorder? shape;
  BorderSide? side;
  VisualDensity? visualDensity;
  MaterialTapTargetSize? materialTapTargetSize;
  Clip? clipBehavior;
  Widget? deleteIcon;
  Color? deleteIconColor;
  VoidCallback? onPressed;
  ValueChanged<bool>? onSelected;
  VoidCallback? onDeleted;
  Key? widgetKey;
}

Widget? _resolveChipAvatar(Object? value, {required bool asIcon}) {
  if (value is Widget) {
    return value;
  }
  if (value is Icon) {
    return CircleAvatar(child: value);
  }
  if (value is IconData) {
    return CircleAvatar(child: Icon(value));
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final background = parseColor(map['backgroundColor'] ?? map['background']);
    final foreground = parseColor(map['foregroundColor'] ?? map['foreground']);
    final radius = toDouble(map['radius']);
    final iconValue = map['icon'] ?? map['name'];
    final textValue = map['text'] ?? map['label'];
    final imageValue = map['image'] ?? map['asset'] ?? map['src'];
    ImageProvider? image;
    if (imageValue != null) {
      final src = imageValue.toString();
      image = src.startsWith('http')
          ? NetworkImage(src)
          : AssetImage(src) as ImageProvider;
    }
    Widget? child;
    if (iconValue != null) {
      final icon = resolveIcon({'name': iconValue});
      if (icon != null) {
        child = Icon(icon);
      }
    } else if (textValue != null) {
      child = Text(textValue.toString());
    }
    return CircleAvatar(
      backgroundColor: background,
      foregroundColor: foreground,
      radius: radius,
      backgroundImage: image,
      child: child,
    );
  }
  if (value is String) {
    if (asIcon) {
      final icon = resolveIcon({'name': value});
      if (icon != null) {
        return CircleAvatar(child: Icon(icon));
      }
    }
    return CircleAvatar(child: Text(value));
  }
  return null;
}
