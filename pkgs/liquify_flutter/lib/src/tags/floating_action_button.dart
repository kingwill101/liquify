import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FloatingActionButtonTag extends WidgetTagBase
    with CustomTagParser, AsyncTag {
  FloatingActionButtonTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildFab(evaluator, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildFab(evaluator, config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('floating_action_button').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endfloating_action_button').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'floating_action_button',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FabConfig _parseConfig(Evaluator evaluator) {
    final config = _FabConfig();
    Object? actionValue;
    Object? onPressedValue;
    Object? childValue;
    Object? iconValue;
    Object? labelValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    final namedValues = <String, Object?>{};

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        case 'icon':
          iconValue = value;
          break;
        case 'label':
        case 'text':
        case 'value':
          labelValue = value;
          break;
        case 'tooltip':
          config.tooltip = value?.toString();
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'foregroundColor':
          config.foregroundColor = parseColor(value);
          break;
        case 'focusColor':
          config.focusColor = parseColor(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'splashColor':
          config.splashColor = parseColor(value);
          break;
        case 'heroTag':
          config.heroTag = value;
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'focusElevation':
          config.focusElevation = toDouble(value);
          break;
        case 'hoverElevation':
          config.hoverElevation = toDouble(value);
          break;
        case 'highlightElevation':
          config.highlightElevation = toDouble(value);
          break;
        case 'disabledElevation':
          config.disabledElevation = toDouble(value);
          break;
        case 'mini':
          config.mini = toBool(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'focusNode':
          if (value is FocusNode) {
            config.focusNode = value;
          }
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'materialTapTargetSize':
          config.materialTapTargetSize = parseMaterialTapTargetSize(value);
          break;
        case 'isExtended':
          config.isExtended = toBool(value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'mouseCursor':
          config.mouseCursor = parseMouseCursor(value);
          break;
        case 'extendedIconLabelSpacing':
          config.extendedIconLabelSpacing = toDouble(value);
          break;
        case 'extendedPadding':
          namedValues[name] = value;
          break;
        case 'extendedTextStyle':
          config.extendedTextStyle = parseTextStyle(value);
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
          handleUnknownArg('floating_action_button', name);
          break;
      }
    }

    config.extendedPadding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'extendedPadding',
      parser: parseEdgeInsetsGeometry,
    );
    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      childValue = resolvedChild;
    }
    config.child = resolveTextWidget(childValue) ?? resolveIconWidget(childValue);
    config.icon = resolveIconWidget(iconValue);
    config.label = resolveTextWidget(labelValue);

    final ids = resolveIds(
      evaluator,
      'floating_action_button',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'floating_action_button',
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

    return config;
  }
}

class _FabConfig {
  VoidCallback? onPressed;
  Widget? child;
  Widget? icon;
  Widget? label;
  String? tooltip;
  Color? foregroundColor;
  Color? backgroundColor;
  Color? focusColor;
  Color? hoverColor;
  Color? splashColor;
  Object? heroTag;
  double? elevation;
  double? focusElevation;
  double? hoverElevation;
  double? highlightElevation;
  double? disabledElevation;
  bool? mini;
  ShapeBorder? shape;
  Clip? clipBehavior;
  FocusNode? focusNode;
  bool? autofocus;
  MaterialTapTargetSize? materialTapTargetSize;
  bool? isExtended;
  bool? enableFeedback;
  MouseCursor? mouseCursor;
  double? extendedIconLabelSpacing;
  EdgeInsetsGeometry? extendedPadding;
  TextStyle? extendedTextStyle;
  Key? widgetKey;
}

Widget _buildFab(
  Evaluator evaluator,
  _FabConfig config,
  List<Widget> children,
) {
  final childFromBody =
      children.isEmpty ? null : WidgetTagBase.asWidgets(children).length == 1
          ? children.first
          : Column(children: children);
  final resolvedChild = config.child ?? childFromBody;

  final useExtended = config.isExtended == true || config.label != null;
  if (useExtended) {
    if (config.heroTag != null) {
      return FloatingActionButton.extended(
        key: config.widgetKey,
        tooltip: config.tooltip,
        foregroundColor: config.foregroundColor,
        backgroundColor: config.backgroundColor,
        focusColor: config.focusColor,
        hoverColor: config.hoverColor,
        splashColor: config.splashColor,
        heroTag: config.heroTag,
        elevation: config.elevation,
        focusElevation: config.focusElevation,
        hoverElevation: config.hoverElevation,
        highlightElevation: config.highlightElevation,
        disabledElevation: config.disabledElevation,
        onPressed: config.onPressed,
        mouseCursor: config.mouseCursor,
        shape: config.shape,
        isExtended: config.isExtended ?? true,
        materialTapTargetSize: config.materialTapTargetSize,
        clipBehavior: config.clipBehavior ?? Clip.none,
        focusNode: config.focusNode,
        autofocus: config.autofocus ?? false,
        extendedIconLabelSpacing: config.extendedIconLabelSpacing,
        extendedPadding: config.extendedPadding,
        extendedTextStyle: config.extendedTextStyle,
        icon: config.icon,
        label:
            config.label ?? resolveTextWidget(resolvedChild) ?? const Text(''),
        enableFeedback: config.enableFeedback,
      );
    }
    return FloatingActionButton.extended(
      key: config.widgetKey,
      tooltip: config.tooltip,
      foregroundColor: config.foregroundColor,
      backgroundColor: config.backgroundColor,
      focusColor: config.focusColor,
      hoverColor: config.hoverColor,
      splashColor: config.splashColor,
      elevation: config.elevation,
      focusElevation: config.focusElevation,
      hoverElevation: config.hoverElevation,
      highlightElevation: config.highlightElevation,
      disabledElevation: config.disabledElevation,
      onPressed: config.onPressed,
      mouseCursor: config.mouseCursor,
      shape: config.shape,
      isExtended: config.isExtended ?? true,
      materialTapTargetSize: config.materialTapTargetSize,
      clipBehavior: config.clipBehavior ?? Clip.none,
      focusNode: config.focusNode,
      autofocus: config.autofocus ?? false,
      extendedIconLabelSpacing: config.extendedIconLabelSpacing,
      extendedPadding: config.extendedPadding,
      extendedTextStyle: config.extendedTextStyle,
      icon: config.icon,
      label: config.label ?? resolveTextWidget(resolvedChild) ?? const Text(''),
      enableFeedback: config.enableFeedback,
    );
  }

  if (config.heroTag != null) {
    return FloatingActionButton(
      key: config.widgetKey,
      tooltip: config.tooltip,
      foregroundColor: config.foregroundColor,
      backgroundColor: config.backgroundColor,
      focusColor: config.focusColor,
      hoverColor: config.hoverColor,
      splashColor: config.splashColor,
      heroTag: config.heroTag,
      elevation: config.elevation,
      focusElevation: config.focusElevation,
      hoverElevation: config.hoverElevation,
      highlightElevation: config.highlightElevation,
      disabledElevation: config.disabledElevation,
      onPressed: config.onPressed,
      mouseCursor: config.mouseCursor,
      mini: config.mini ?? false,
      shape: config.shape,
      clipBehavior: config.clipBehavior ?? Clip.none,
      focusNode: config.focusNode,
      autofocus: config.autofocus ?? false,
      materialTapTargetSize: config.materialTapTargetSize,
      isExtended: config.isExtended ?? false,
      enableFeedback: config.enableFeedback,
      child: resolvedChild ?? config.icon,
    );
  }
  return FloatingActionButton(
    key: config.widgetKey,
    tooltip: config.tooltip,
    foregroundColor: config.foregroundColor,
    backgroundColor: config.backgroundColor,
    focusColor: config.focusColor,
    hoverColor: config.hoverColor,
    splashColor: config.splashColor,
    elevation: config.elevation,
    focusElevation: config.focusElevation,
    hoverElevation: config.hoverElevation,
    highlightElevation: config.highlightElevation,
    disabledElevation: config.disabledElevation,
    onPressed: config.onPressed,
    mouseCursor: config.mouseCursor,
    mini: config.mini ?? false,
    shape: config.shape,
    clipBehavior: config.clipBehavior ?? Clip.none,
    focusNode: config.focusNode,
    autofocus: config.autofocus ?? false,
    materialTapTargetSize: config.materialTapTargetSize,
    isExtended: config.isExtended ?? false,
    enableFeedback: config.enableFeedback,
    child: resolvedChild ?? config.icon,
  );
}
