// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ButtonTag extends WidgetTagBase with AsyncTag {
  ButtonTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    dynamic textValue;
    dynamic action;
    dynamic onPressed;
    dynamic onLongPress;
    dynamic onHover;
    dynamic onFocusChange;
    ButtonStyle? style;
    FocusNode? focusNode;
    bool? autofocus;
    Clip? clipBehavior;
    MaterialStatesController? statesController;
    bool? isSemanticButton;
    Object? childValue;
    Object? iconValue;
    IconAlignment? iconAlignment;
    double? fontSize;
    FontWeight? fontWeight;
    FontStyle? fontStyle;
    Color? backgroundColor;
    Color? foregroundColor;
    EdgeInsetsGeometry? padding;
    double? radius;
    double? minWidth;
    double? minHeight;
    String? variant;
    String? widgetIdValue;
    String? widgetKeyValue;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'text':
        case 'label':
        case 'value':
          textValue = evaluator.evaluate(arg.value);
          break;
        case 'action':
          action = evaluator.evaluate(arg.value);
          break;
        case 'onPressed':
          onPressed = evaluator.evaluate(arg.value);
          break;
        case 'onLongPress':
          onLongPress = evaluator.evaluate(arg.value);
          break;
        case 'onHover':
          onHover = evaluator.evaluate(arg.value);
          break;
        case 'onFocusChange':
          onFocusChange = evaluator.evaluate(arg.value);
          break;
        case 'style':
          final value = evaluator.evaluate(arg.value);
          if (value is ButtonStyle) {
            style = value;
          }
          break;
        case 'focusNode':
          final value = evaluator.evaluate(arg.value);
          if (value is FocusNode) {
            focusNode = value;
          }
          break;
        case 'autofocus':
          autofocus = toBool(evaluator.evaluate(arg.value));
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'statesController':
          final value = evaluator.evaluate(arg.value);
          if (value is MaterialStatesController) {
            statesController = value;
          }
          break;
        case 'isSemanticButton':
          isSemanticButton = toBool(evaluator.evaluate(arg.value));
          break;
        case 'child':
          childValue = evaluator.evaluate(arg.value);
          break;
        case 'icon':
          iconValue = evaluator.evaluate(arg.value);
          break;
        case 'iconAlignment':
          iconAlignment = parseIconAlignment(evaluator.evaluate(arg.value));
          break;
        case 'ink':
        case 'ripple':
          evaluator.evaluate(arg.value);
          break;
        case 'fontSize':
        case 'size':
          fontSize = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'fontWeight':
        case 'weight':
          fontWeight = parseFontWeight(evaluator.evaluate(arg.value));
          break;
        case 'fontStyle':
          fontStyle = parseFontStyle(evaluator.evaluate(arg.value));
          break;
        case 'backgroundColor':
        case 'background':
        case 'bg':
          backgroundColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'foregroundColor':
        case 'textColor':
        case 'foreground':
        case 'fg':
          foregroundColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'radius':
          radius = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'minimumWidth':
        case 'minWidth':
          minWidth = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'width':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'minimumHeight':
        case 'minHeight':
          minHeight = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'height':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'variant':
          variant = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'id':
          widgetIdValue = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'key':
          widgetKeyValue = evaluator.evaluate(arg.value)?.toString();
          break;
        default:
          handleUnknownArg('button', name);
          break;
      }
    }
    padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    final resolvedWidth = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'width',
      parser: toDouble,
    );
    if (resolvedWidth != null) {
      minWidth ??= resolvedWidth;
    }
    final resolvedHeight = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    if (resolvedHeight != null) {
      minHeight ??= resolvedHeight;
    }
    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      childValue = resolvedChild;
    }
    final resolvedColor = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );
    if (resolvedColor != null && backgroundColor == null) {
      backgroundColor = resolvedColor;
    }
    textValue ??= _evaluatePositionalValue(evaluator, content);
    final label = textValue == null
        ? ''
        : applyFilters(textValue, evaluator).toString();
    final resolvedId = resolveWidgetId(
      evaluator,
      'button',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final widgetKeyText = widgetKeyValue?.trim();
    final resolvedKeyValue =
        (widgetKeyText != null && widgetKeyText.isNotEmpty)
            ? widgetKeyText
            : resolvedId;
    final widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = action is String ? action : null;
    final baseEvent = buildWidgetEvent(
      tag: 'button',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      props: {'label': label, 'variant': variant},
    );
    final callback =
        resolveActionCallback(
          evaluator,
          onPressed,
          event: {...baseEvent, 'event': 'pressed'},
          actionValue: actionName,
        ) ??
        resolveActionCallback(
          evaluator,
          action,
          event: {...baseEvent, 'event': 'pressed'},
          actionValue: actionName,
        );
    final longPress = resolveActionCallback(
      evaluator,
      onLongPress,
      event: {...baseEvent, 'event': 'long_press'},
      actionValue: actionName,
    );
    final hover = resolveBoolActionCallback(
      evaluator,
      onHover,
      event: {...baseEvent, 'event': 'hover'},
      actionValue: actionName,
    );
    final focusChange = resolveBoolActionCallback(
      evaluator,
      onFocusChange,
      event: {...baseEvent, 'event': 'focus'},
      actionValue: actionName,
    );
    _applyVariantStyles(variant, backgroundColor, foregroundColor, (bg, fg) {
      backgroundColor = bg ?? backgroundColor;
      foregroundColor = fg ?? foregroundColor;
    });
    final textStyle =
        (fontSize != null ||
            fontWeight != null ||
            fontStyle != null ||
            foregroundColor != null)
        ? TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            color: foregroundColor,
          )
        : null;

    final hasStyleOverrides =
        backgroundColor != null ||
        foregroundColor != null ||
        padding != null ||
        minWidth != null ||
        minHeight != null ||
        radius != null ||
        fontSize != null ||
        fontWeight != null ||
        fontStyle != null;
    final styleFrom = hasStyleOverrides
        ? TextButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: padding,
            minimumSize: (minWidth != null || minHeight != null)
                ? Size(minWidth ?? 0, minHeight ?? 0)
                : null,
            shape: radius == null
                ? null
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
            textStyle:
                (fontSize != null || fontWeight != null || fontStyle != null)
                ? TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    fontStyle: fontStyle,
                  )
                : null,
          )
        : null;
    final resolvedStyle = styleFrom == null
        ? style
        : (style == null ? styleFrom : style.merge(styleFrom));
    Widget child = _resolveButtonChild(childValue, label, textStyle);
    if (iconValue != null) {
      final icon = _resolveButtonIcon(iconValue);
      buffer.write(
        TextButton.icon(
          key: widgetKey,
          onPressed: callback,
          onLongPress: longPress,
          onHover: hover,
          onFocusChange: focusChange,
          style: resolvedStyle,
          focusNode: focusNode,
          autofocus: autofocus ?? false,
          clipBehavior: clipBehavior,
          statesController: statesController,
          icon: icon,
          label: child,
          iconAlignment: iconAlignment,
        ),
      );
      return;
    }
    buffer.write(
      TextButton(
        key: widgetKey,
        onPressed: callback,
        onLongPress: longPress,
        onHover: hover,
        onFocusChange: focusChange,
        style: resolvedStyle,
        focusNode: focusNode,
        autofocus: autofocus ?? false,
        clipBehavior: clipBehavior,
        statesController: statesController,
        isSemanticButton: isSemanticButton,
        child: child,
      ),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    dynamic textValue;
    dynamic action;
    dynamic onPressed;
    dynamic onLongPress;
    dynamic onHover;
    dynamic onFocusChange;
    ButtonStyle? style;
    FocusNode? focusNode;
    bool? autofocus;
    Clip? clipBehavior;
    MaterialStatesController? statesController;
    bool? isSemanticButton;
    Object? childValue;
    Object? iconValue;
    IconAlignment? iconAlignment;
    double? fontSize;
    FontWeight? fontWeight;
    FontStyle? fontStyle;
    Color? backgroundColor;
    Color? foregroundColor;
    EdgeInsetsGeometry? padding;
    double? radius;
    double? minWidth;
    double? minHeight;
    String? variant;
    String? widgetIdValue;
    String? widgetKeyValue;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'text':
        case 'label':
        case 'value':
          textValue = evaluator.evaluate(arg.value);
          break;
        case 'action':
          action = evaluator.evaluate(arg.value);
          break;
        case 'onPressed':
          onPressed = evaluator.evaluate(arg.value);
          break;
        case 'onLongPress':
          onLongPress = evaluator.evaluate(arg.value);
          break;
        case 'onHover':
          onHover = evaluator.evaluate(arg.value);
          break;
        case 'onFocusChange':
          onFocusChange = evaluator.evaluate(arg.value);
          break;
        case 'style':
          final value = evaluator.evaluate(arg.value);
          if (value is ButtonStyle) {
            style = value;
          }
          break;
        case 'focusNode':
          final value = evaluator.evaluate(arg.value);
          if (value is FocusNode) {
            focusNode = value;
          }
          break;
        case 'autofocus':
          autofocus = toBool(evaluator.evaluate(arg.value));
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'statesController':
          final value = evaluator.evaluate(arg.value);
          if (value is MaterialStatesController) {
            statesController = value;
          }
          break;
        case 'isSemanticButton':
          isSemanticButton = toBool(evaluator.evaluate(arg.value));
          break;
        case 'child':
          childValue = evaluator.evaluate(arg.value);
          namedValues[name] = childValue;
          break;
        case 'icon':
          iconValue = evaluator.evaluate(arg.value);
          break;
        case 'iconAlignment':
          iconAlignment = parseIconAlignment(evaluator.evaluate(arg.value));
          break;
        case 'ink':
        case 'ripple':
          evaluator.evaluate(arg.value);
          break;
        case 'fontSize':
        case 'size':
          fontSize = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'fontWeight':
        case 'weight':
          fontWeight = parseFontWeight(evaluator.evaluate(arg.value));
          break;
        case 'fontStyle':
          fontStyle = parseFontStyle(evaluator.evaluate(arg.value));
          break;
        case 'backgroundColor':
        case 'background':
        case 'bg':
          backgroundColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'foregroundColor':
        case 'textColor':
        case 'foreground':
        case 'fg':
          foregroundColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'radius':
          radius = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'minimumWidth':
        case 'minWidth':
          minWidth = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'width':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'minimumHeight':
        case 'minHeight':
          minHeight = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'height':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'variant':
          variant = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'id':
          widgetIdValue = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'key':
          widgetKeyValue = evaluator.evaluate(arg.value)?.toString();
          break;
        default:
          handleUnknownArg('button', name);
          break;
      }
    }
    padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    final resolvedWidth = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'width',
      parser: toDouble,
    );
    if (resolvedWidth != null) {
      minWidth ??= resolvedWidth;
    }
    final resolvedHeight = resolvePropertyValue<double?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'height',
      parser: toDouble,
    );
    if (resolvedHeight != null) {
      minHeight ??= resolvedHeight;
    }
    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      childValue = resolvedChild;
    }
    final resolvedColor = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );
    if (resolvedColor != null && backgroundColor == null) {
      backgroundColor = resolvedColor;
    }
    textValue ??= _evaluatePositionalValue(evaluator, content);
    final label = textValue == null
        ? ''
        : (await applyFiltersAsync(textValue, evaluator)).toString();
    final resolvedId = resolveWidgetId(
      evaluator,
      'button',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final widgetKeyText = widgetKeyValue?.trim();
    final resolvedKeyValue =
        (widgetKeyText != null && widgetKeyText.isNotEmpty)
            ? widgetKeyText
            : resolvedId;
    final widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = action is String ? action : null;
    final baseEvent = buildWidgetEvent(
      tag: 'button',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      props: {'label': label, 'variant': variant},
    );
    final callback =
        resolveActionCallback(
          evaluator,
          onPressed,
          event: {...baseEvent, 'event': 'pressed'},
          actionValue: actionName,
        ) ??
        resolveActionCallback(
          evaluator,
          action,
          event: {...baseEvent, 'event': 'pressed'},
          actionValue: actionName,
        );
    final longPress = resolveActionCallback(
      evaluator,
      onLongPress,
      event: {...baseEvent, 'event': 'long_press'},
      actionValue: actionName,
    );
    final hover = resolveBoolActionCallback(
      evaluator,
      onHover,
      event: {...baseEvent, 'event': 'hover'},
      actionValue: actionName,
    );
    final focusChange = resolveBoolActionCallback(
      evaluator,
      onFocusChange,
      event: {...baseEvent, 'event': 'focus'},
      actionValue: actionName,
    );
    _applyVariantStyles(variant, backgroundColor, foregroundColor, (bg, fg) {
      backgroundColor = bg ?? backgroundColor;
      foregroundColor = fg ?? foregroundColor;
    });
    final textStyle =
        (fontSize != null ||
            fontWeight != null ||
            fontStyle != null ||
            foregroundColor != null)
        ? TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            color: foregroundColor,
          )
        : null;

    final hasStyleOverrides =
        backgroundColor != null ||
        foregroundColor != null ||
        padding != null ||
        minWidth != null ||
        minHeight != null ||
        radius != null ||
        fontSize != null ||
        fontWeight != null ||
        fontStyle != null;
    final styleFrom = hasStyleOverrides
        ? TextButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: padding,
            minimumSize: (minWidth != null || minHeight != null)
                ? Size(minWidth ?? 0, minHeight ?? 0)
                : null,
            shape: radius == null
                ? null
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
            textStyle:
                (fontSize != null || fontWeight != null || fontStyle != null)
                ? TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    fontStyle: fontStyle,
                  )
                : null,
          )
        : null;
    final resolvedStyle = styleFrom == null
        ? style
        : (style == null ? styleFrom : style.merge(styleFrom));
    Widget child = _resolveButtonChild(childValue, label, textStyle);
    if (iconValue != null) {
      final icon = _resolveButtonIcon(iconValue);
      buffer.write(
        TextButton.icon(
          key: widgetKey,
          onPressed: callback,
          onLongPress: longPress,
          onHover: hover,
          onFocusChange: focusChange,
          style: resolvedStyle,
          focusNode: focusNode,
          autofocus: autofocus ?? false,
          clipBehavior: clipBehavior,
          statesController: statesController,
          icon: icon,
          label: child,
          iconAlignment: iconAlignment,
        ),
      );
      return;
    }
    buffer.write(
      TextButton(
        key: widgetKey,
        onPressed: callback,
        onLongPress: longPress,
        onHover: hover,
        onFocusChange: focusChange,
        style: resolvedStyle,
        focusNode: focusNode,
        autofocus: autofocus ?? false,
        clipBehavior: clipBehavior,
        statesController: statesController,
        isSemanticButton: isSemanticButton,
        child: child,
      ),
    );
  }
}

void _applyVariantStyles(
  String? variant,
  Color? backgroundColor,
  Color? foregroundColor,
  void Function(Color?, Color?) apply,
) {
  if (variant == null || variant.isEmpty) {
    return;
  }
  final normalized = variant.toLowerCase().trim();
  switch (normalized) {
    case 'operator':
    case 'accent':
      apply(
        backgroundColor ?? const Color(0xffffb020),
        foregroundColor ?? const Color(0xfff6f7fb),
      );
      return;
    case 'action':
      apply(
        backgroundColor ?? const Color(0xff6c6f78),
        foregroundColor ?? const Color(0xfff6f7fb),
      );
      return;
    case 'digit':
    default:
      apply(
        backgroundColor ?? const Color(0xff343741),
        foregroundColor ?? const Color(0xfff6f7fb),
      );
  }
}

Widget _resolveButtonChild(
  Object? childValue,
  String label,
  TextStyle? textStyle,
) {
  if (childValue is Widget) {
    return childValue;
  }
  if (childValue != null) {
    return Text(childValue.toString(), style: textStyle);
  }
  return Text(label, style: textStyle);
}

Widget _resolveButtonIcon(Object? iconValue) {
  if (iconValue is Widget) {
    return iconValue;
  }
  if (iconValue is IconData) {
    return Icon(iconValue);
  }
  final props = <String, dynamic>{'icon': iconValue};
  final resolved = resolveIcon(props);
  if (resolved != null) {
    return Icon(resolved);
  }
  return const SizedBox.shrink();
}

dynamic _evaluatePositionalValue(Evaluator evaluator, List<ASTNode> content) {
  final positional = content.where((node) => node is! NamedArgument).toList();
  if (positional.isEmpty) {
    return null;
  }
  if (positional.length == 1) {
    return evaluator.evaluate(positional.first);
  }
  final buffer = StringBuffer();
  for (final node in positional) {
    buffer.write(evaluator.evaluate(node));
  }
  return buffer.toString();
}
