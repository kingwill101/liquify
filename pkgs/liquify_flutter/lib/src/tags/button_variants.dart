// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

enum MaterialButtonVariant { elevated, outlined, filled }

class MaterialButtonTag extends WidgetTagBase with AsyncTag {
  MaterialButtonTag(this.variant, this.tagName, super.content, super.filters);

  final MaterialButtonVariant variant;
  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildButton(evaluator, config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildButton(evaluator, config));
  }

  _MaterialButtonConfig _parseConfig(Evaluator evaluator) {
    final config = _MaterialButtonConfig(tagName: tagName);
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
          config.namedValues[name] = value;
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        case 'icon':
          config.namedValues[name] = value;
          break;
        case 'iconAlignment':
          config.iconAlignment = parseIconAlignment(value);
          break;
        case 'onPressed':
          config.onPressed = value;
          break;
        case 'onLongPress':
          config.onLongPress = value;
          break;
        case 'onHover':
          config.onHover = value;
          break;
        case 'onFocusChange':
          config.onFocusChange = value;
          break;
        case 'action':
          config.action = value;
          break;
        case 'style':
          if (value is ButtonStyle) {
            config.style = value;
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
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'statesController':
          if (value is MaterialStatesController) {
            config.statesController = value;
          }
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'foregroundColor':
          config.foregroundColor = parseColor(value);
          break;
        case 'padding':
          config.namedValues[name] = value;
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'radius':
          config.radius = toDouble(value);
          break;
        case 'fontSize':
          config.fontSize = toDouble(value);
          break;
        case 'fontWeight':
          config.fontWeight = parseFontWeight(value);
          break;
        case 'fontStyle':
          config.fontStyle = parseFontStyle(value);
          break;
        case 'id':
          config.widgetId = value?.toString();
          break;
        case 'key':
          config.widgetKey = value?.toString();
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }
    return config;
  }

  Widget _buildButton(Evaluator evaluator, _MaterialButtonConfig config) {
    final ids = resolveIds(
      evaluator,
      tagName,
      id: config.widgetId,
      key: config.widgetKey,
    );

    final labelWidget = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: config.namedValues,
      name: 'label',
      parser: resolveTextWidget,
    );
    final childWidget = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: config.namedValues,
      name: 'child',
      parser: resolveTextWidget,
    );
    final iconWidget = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: config.namedValues,
      name: 'icon',
      parser: resolveIconWidget,
    );

    final labelText = _extractLabel(labelWidget ?? childWidget);
    final actionName = config.action is String ? config.action as String : null;
    final baseEvent = buildWidgetEvent(
      tag: tagName,
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      props: {'label': labelText},
    );

    final onPressed =
        resolveActionCallback(
          evaluator,
          config.onPressed,
          event: {...baseEvent, 'event': 'pressed'},
          actionValue: actionName,
        ) ??
        resolveActionCallback(
          evaluator,
          config.action,
          event: {...baseEvent, 'event': 'pressed'},
          actionValue: actionName,
        );
    final onLongPress = resolveActionCallback(
      evaluator,
      config.onLongPress,
      event: {...baseEvent, 'event': 'long_press'},
      actionValue: actionName,
    );
    final onHover = resolveBoolActionCallback(
      evaluator,
      config.onHover,
      event: {...baseEvent, 'event': 'hover'},
      actionValue: actionName,
    );
    final onFocusChange = resolveBoolActionCallback(
      evaluator,
      config.onFocusChange,
      event: {...baseEvent, 'event': 'focus'},
      actionValue: actionName,
    );

    final padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: config.namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );

    final textStyle =
        (config.fontSize != null ||
            config.fontWeight != null ||
            config.fontStyle != null)
        ? TextStyle(
            fontSize: config.fontSize,
            fontWeight: config.fontWeight,
            fontStyle: config.fontStyle,
          )
        : null;

    final styleOverride = _buildStyle(
      variant,
      backgroundColor: config.backgroundColor,
      foregroundColor: config.foregroundColor,
      padding: padding,
      elevation: config.elevation,
      radius: config.radius,
      textStyle: textStyle,
    );

    final style = styleOverride == null
        ? config.style
        : (config.style == null
              ? styleOverride
              : config.style!.merge(styleOverride));

    final child = childWidget ?? labelWidget ?? const SizedBox.shrink();
    final label = labelWidget ?? childWidget ?? const SizedBox.shrink();

    switch (variant) {
      case MaterialButtonVariant.elevated:
        if (iconWidget != null) {
          return ElevatedButton.icon(
            key: ids.key,
            onPressed: onPressed,
            onLongPress: onLongPress,
            onHover: onHover,
            onFocusChange: onFocusChange,
            style: style,
            focusNode: config.focusNode,
            autofocus: config.autofocus ?? false,
            clipBehavior: config.clipBehavior,
            statesController: config.statesController,
            icon: iconWidget,
            label: label,
            iconAlignment: config.iconAlignment,
          );
        }
        return ElevatedButton(
          key: ids.key,
          onPressed: onPressed,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          style: style,
          focusNode: config.focusNode,
          autofocus: config.autofocus ?? false,
          clipBehavior: config.clipBehavior,
          statesController: config.statesController,
          child: child,
        );
      case MaterialButtonVariant.outlined:
        if (iconWidget != null) {
          return OutlinedButton.icon(
            key: ids.key,
            onPressed: onPressed,
            onLongPress: onLongPress,
            onHover: onHover,
            onFocusChange: onFocusChange,
            style: style,
            focusNode: config.focusNode,
            autofocus: config.autofocus ?? false,
            clipBehavior: config.clipBehavior,
            statesController: config.statesController,
            icon: iconWidget,
            label: label,
            iconAlignment: config.iconAlignment,
          );
        }
        return OutlinedButton(
          key: ids.key,
          onPressed: onPressed,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          style: style,
          focusNode: config.focusNode,
          autofocus: config.autofocus ?? false,
          clipBehavior: config.clipBehavior,
          statesController: config.statesController,
          child: child,
        );
      case MaterialButtonVariant.filled:
        if (iconWidget != null) {
          return FilledButton.icon(
            key: ids.key,
            onPressed: onPressed,
            onLongPress: onLongPress,
            onHover: onHover,
            onFocusChange: onFocusChange,
            style: style,
            focusNode: config.focusNode,
            autofocus: config.autofocus ?? false,
            clipBehavior: config.clipBehavior,
            statesController: config.statesController,
            icon: iconWidget,
            label: label,
            iconAlignment: config.iconAlignment,
          );
        }
        return FilledButton(
          key: ids.key,
          onPressed: onPressed,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          style: style,
          focusNode: config.focusNode,
          autofocus: config.autofocus ?? false,
          clipBehavior: config.clipBehavior,
          statesController: config.statesController,
          child: child,
        );
    }
  }

  String? _extractLabel(Widget? widget) {
    if (widget is Text) {
      return widget.data;
    }
    return null;
  }
}

class _MaterialButtonConfig {
  _MaterialButtonConfig({required this.tagName});

  final String tagName;
  final Map<String, Object?> namedValues = {};
  Object? action;
  Object? onPressed;
  Object? onLongPress;
  Object? onHover;
  Object? onFocusChange;
  ButtonStyle? style;
  FocusNode? focusNode;
  bool? autofocus;
  Clip? clipBehavior;
  MaterialStatesController? statesController;
  IconAlignment? iconAlignment;
  Color? backgroundColor;
  Color? foregroundColor;
  double? elevation;
  double? radius;
  double? fontSize;
  FontWeight? fontWeight;
  FontStyle? fontStyle;
  String? widgetId;
  String? widgetKey;
}

ButtonStyle? _buildStyle(
  MaterialButtonVariant variant, {
  Color? backgroundColor,
  Color? foregroundColor,
  EdgeInsetsGeometry? padding,
  double? elevation,
  double? radius,
  TextStyle? textStyle,
}) {
  final hasOverrides =
      backgroundColor != null ||
      foregroundColor != null ||
      padding != null ||
      elevation != null ||
      radius != null ||
      textStyle != null;
  if (!hasOverrides) {
    return null;
  }

  final shape = radius == null
      ? null
      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  switch (variant) {
    case MaterialButtonVariant.elevated:
      return ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        elevation: elevation,
        textStyle: textStyle,
        shape: shape,
      );
    case MaterialButtonVariant.outlined:
      return OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        padding: padding,
        textStyle: textStyle,
        shape: shape,
      );
    case MaterialButtonVariant.filled:
      return FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        elevation: elevation,
        textStyle: textStyle,
        shape: shape,
      );
  }
}
