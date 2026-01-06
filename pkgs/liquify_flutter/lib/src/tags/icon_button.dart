// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

enum IconButtonVariant { standard, filled, filledTonal, outlined }

class IconButtonTag extends WidgetTagBase with AsyncTag {
  IconButtonTag(this.variant, this.tagName, super.content, super.filters);

  final IconButtonVariant variant;
  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildIconButton(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildIconButton(config));
  }

  _IconButtonConfig _parseConfig(Evaluator evaluator) {
    final config = _IconButtonConfig(variant: variant, tagName: tagName);
    Object? actionValue;
    Object? onPressedValue;
    Object? onLongPressValue;
    Object? onHoverValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? iconValue;
    Object? selectedIconValue;
    final namedValues = <String, Object?>{};

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'icon':
          iconValue = value;
          break;
        case 'selectedIcon':
          selectedIconValue = value;
          break;
        case 'isSelected':
          config.isSelected = toBool(value);
          break;
        case 'iconSize':
          config.iconSize = toDouble(value);
          break;
        case 'visualDensity':
          config.visualDensity = parseVisualDensity(value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'alignment':
          config.alignment = parseAlignmentGeometry(value);
          break;
        case 'splashRadius':
          config.splashRadius = toDouble(value);
          break;
        case 'color':
          config.color = parseColor(value);
          break;
        case 'focusColor':
          config.focusColor = parseColor(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'highlightColor':
          config.highlightColor = parseColor(value);
          break;
        case 'splashColor':
          config.splashColor = parseColor(value);
          break;
        case 'disabledColor':
          config.disabledColor = parseColor(value);
          break;
        case 'onPressed':
          onPressedValue = value;
          break;
        case 'onLongPress':
          onLongPressValue = value;
          break;
        case 'onHover':
          onHoverValue = value;
          break;
        case 'mouseCursor':
          if (value is MouseCursor) {
            config.mouseCursor = value;
          }
          break;
        case 'focusNode':
          if (value is FocusNode) {
            config.focusNode = value;
          }
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'tooltip':
          config.tooltip = value?.toString();
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'constraints':
          config.constraints = parseBoxConstraints(value);
          break;
        case 'style':
          if (value is ButtonStyle) {
            config.style = value;
          }
          break;
        case 'statesController':
          if (value is MaterialStatesController) {
            config.statesController = value;
          }
          break;
        case 'action':
          actionValue = value;
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

    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    config.icon = resolveIconWidget(iconValue);
    config.selectedIcon = resolveIconWidget(selectedIconValue);
    if (config.icon == null) {
      throw Exception('${config.tagName} tag requires "icon"');
    }

    final ids = resolveIds(
      evaluator,
      tagName,
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: tagName,
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'pressed',
    );
    config.onPressed =
        resolveActionCallback(
          evaluator,
          onPressedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    config.onLongPress = resolveActionCallback(
      evaluator,
      onLongPressValue,
      event: {...baseEvent, 'event': 'long_press'},
      actionValue: actionName,
    );
    config.onHover = resolveBoolActionCallback(
      evaluator,
      onHoverValue,
      event: {...baseEvent, 'event': 'hover'},
      actionValue: actionName,
    );
    return config;
  }
}

class _IconButtonConfig {
  _IconButtonConfig({required this.variant, required this.tagName});

  final IconButtonVariant variant;
  final String tagName;
  Widget? icon;
  Widget? selectedIcon;
  bool? isSelected;
  double? iconSize;
  VisualDensity? visualDensity;
  EdgeInsetsGeometry? padding;
  AlignmentGeometry? alignment;
  double? splashRadius;
  Color? color;
  Color? focusColor;
  Color? hoverColor;
  Color? highlightColor;
  Color? splashColor;
  Color? disabledColor;
  VoidCallback? onPressed;
  VoidCallback? onLongPress;
  ValueChanged<bool>? onHover;
  MouseCursor? mouseCursor;
  FocusNode? focusNode;
  bool? autofocus;
  String? tooltip;
  bool? enableFeedback;
  BoxConstraints? constraints;
  ButtonStyle? style;
  MaterialStatesController? statesController;
  Key? widgetKey;
}

Widget _buildIconButton(_IconButtonConfig config) {
  final icon = config.icon ?? const SizedBox.shrink();
  switch (config.variant) {
    case IconButtonVariant.filled:
      return IconButton.filled(
        key: config.widgetKey,
        onPressed: config.onPressed,
        onLongPress: config.onLongPress,
        onHover: config.onHover,
        icon: icon,
        selectedIcon: config.selectedIcon,
        isSelected: config.isSelected,
        iconSize: config.iconSize,
        visualDensity: config.visualDensity,
        padding: config.padding,
        alignment: config.alignment,
        splashRadius: config.splashRadius,
        color: config.color,
        focusColor: config.focusColor,
        hoverColor: config.hoverColor,
        highlightColor: config.highlightColor,
        splashColor: config.splashColor,
        disabledColor: config.disabledColor,
        mouseCursor: config.mouseCursor,
        focusNode: config.focusNode,
        autofocus: config.autofocus ?? false,
        tooltip: config.tooltip,
        enableFeedback: config.enableFeedback,
        constraints: config.constraints,
        style: config.style,
        statesController: config.statesController,
      );
    case IconButtonVariant.filledTonal:
      return IconButton.filledTonal(
        key: config.widgetKey,
        onPressed: config.onPressed,
        onLongPress: config.onLongPress,
        onHover: config.onHover,
        icon: icon,
        selectedIcon: config.selectedIcon,
        isSelected: config.isSelected,
        iconSize: config.iconSize,
        visualDensity: config.visualDensity,
        padding: config.padding,
        alignment: config.alignment,
        splashRadius: config.splashRadius,
        color: config.color,
        focusColor: config.focusColor,
        hoverColor: config.hoverColor,
        highlightColor: config.highlightColor,
        splashColor: config.splashColor,
        disabledColor: config.disabledColor,
        mouseCursor: config.mouseCursor,
        focusNode: config.focusNode,
        autofocus: config.autofocus ?? false,
        tooltip: config.tooltip,
        enableFeedback: config.enableFeedback,
        constraints: config.constraints,
        style: config.style,
        statesController: config.statesController,
      );
    case IconButtonVariant.outlined:
      return IconButton.outlined(
        key: config.widgetKey,
        onPressed: config.onPressed,
        onLongPress: config.onLongPress,
        onHover: config.onHover,
        icon: icon,
        selectedIcon: config.selectedIcon,
        isSelected: config.isSelected,
        iconSize: config.iconSize,
        visualDensity: config.visualDensity,
        padding: config.padding,
        alignment: config.alignment,
        splashRadius: config.splashRadius,
        color: config.color,
        focusColor: config.focusColor,
        hoverColor: config.hoverColor,
        highlightColor: config.highlightColor,
        splashColor: config.splashColor,
        disabledColor: config.disabledColor,
        mouseCursor: config.mouseCursor,
        focusNode: config.focusNode,
        autofocus: config.autofocus ?? false,
        tooltip: config.tooltip,
        enableFeedback: config.enableFeedback,
        constraints: config.constraints,
        style: config.style,
        statesController: config.statesController,
      );
    case IconButtonVariant.standard:
      return IconButton(
        key: config.widgetKey,
        onPressed: config.onPressed,
        onLongPress: config.onLongPress,
        onHover: config.onHover,
        icon: icon,
        selectedIcon: config.selectedIcon,
        isSelected: config.isSelected,
        iconSize: config.iconSize,
        visualDensity: config.visualDensity,
        padding: config.padding,
        alignment: config.alignment,
        splashRadius: config.splashRadius,
        color: config.color,
        focusColor: config.focusColor,
        hoverColor: config.hoverColor,
        highlightColor: config.highlightColor,
        splashColor: config.splashColor,
        disabledColor: config.disabledColor,
        mouseCursor: config.mouseCursor,
        focusNode: config.focusNode,
        autofocus: config.autofocus ?? false,
        tooltip: config.tooltip,
        enableFeedback: config.enableFeedback,
        constraints: config.constraints,
        style: config.style,
        statesController: config.statesController,
      );
  }
}
