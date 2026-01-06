import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SnackBarTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SnackBarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildSnackBar(evaluator, config, namedValues, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildSnackBar(evaluator, config, namedValues, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('snackbar').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsnackbar').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'snackbar',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SnackBarConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _SnackBarConfig();
    Object? actionValue;
    SnackBarAction? actionWidget;
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? onVisibleValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'content':
          config.content = _resolveTextOrWidget(value);
          namedValues[name] = value;
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'margin':
          config.margin = parseEdgeInsetsGeometry(value);
          break;
        case 'padding':
          config.padding = parseEdgeInsetsGeometry(value);
          break;
        case 'width':
          config.width = toDouble(value);
          break;
        case 'behavior':
          config.behavior = parseSnackBarBehavior(value);
          break;
        case 'duration':
          config.duration = parseDuration(value);
          break;
        case 'animation':
          if (value is Animation<double>) {
            config.animation = value;
          }
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'dismissDirection':
          config.dismissDirection = parseDismissDirection(value);
          break;
        case 'showCloseIcon':
          config.showCloseIcon = toBool(value);
          break;
        case 'closeIconColor':
          config.closeIconColor = parseColor(value);
          break;
        case 'actionOverflowThreshold':
          config.actionOverflowThreshold = toDouble(value);
          break;
        case 'actionLabel':
          config.actionLabel = value?.toString();
          break;
        case 'actionTextColor':
          config.actionTextColor = parseColor(value);
          break;
        case 'actionDisabledTextColor':
          config.actionDisabledTextColor = parseColor(value);
          break;
        case 'action':
          if (value is SnackBarAction) {
            actionWidget = value;
            namedValues[name] = value;
          } else {
            actionValue = value;
          }
          break;
        case 'onVisible':
          onVisibleValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('snackbar', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'snackbar',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'snackbar',
      id: resolvedId,
      key: widgetKeyValue ?? resolvedId,
      action: actionName,
      event: 'action',
      props: const {},
    );
    config.onAction = resolveActionCallback(
      evaluator,
      actionValue,
      event: baseEvent,
      actionValue: actionName,
    );
    config.onVisible = resolveActionCallback(
      evaluator,
      onVisibleValue,
      event: buildWidgetEvent(
        tag: 'snackbar',
        id: resolvedId,
        key: widgetKeyValue ?? resolvedId,
        event: 'visible',
        props: const {},
      ),
    );
    config.action = actionWidget;

    return config;
  }
}

class _SnackBarConfig {
  Widget? content;
  Color? backgroundColor;
  double? elevation;
  EdgeInsetsGeometry? margin;
  EdgeInsetsGeometry? padding;
  double? width;
  SnackBarBehavior? behavior;
  Duration? duration;
  Animation<double>? animation;
  ShapeBorder? shape;
  Clip? clipBehavior;
  DismissDirection? dismissDirection;
  bool? showCloseIcon;
  Color? closeIconColor;
  double? actionOverflowThreshold;
  String? actionLabel;
  Color? actionTextColor;
  Color? actionDisabledTextColor;
  VoidCallback? onAction;
  VoidCallback? onVisible;
  SnackBarAction? action;
  Key? widgetKey;
}

Widget _buildSnackBar(
  Evaluator evaluator,
  _SnackBarConfig config,
  Map<String, Object?> namedValues,
  List<Widget> children,
) {
  final resolvedContent = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'content',
    parser: _resolveTextOrWidget,
  );
  final resolvedAction = resolvePropertyValue<SnackBarAction?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'action',
    parser: (value) => value is SnackBarAction ? value : null,
  );
  var content = resolvedContent ?? config.content;
  content ??= children.isNotEmpty ? wrapChildren(children) : const SizedBox();
  final action =
      resolvedAction ??
      config.action ??
      (config.actionLabel == null
          ? null
          : SnackBarAction(
              label: config.actionLabel!,
              onPressed: config.onAction ?? () {},
              textColor: config.actionTextColor,
              disabledTextColor: config.actionDisabledTextColor,
            ));
  return SnackBar(
    key: config.widgetKey,
    content: content,
    backgroundColor: config.backgroundColor,
    elevation: config.elevation,
    margin: config.margin,
    padding: config.padding,
    width: config.width,
    behavior: config.behavior,
    duration: config.duration ?? const Duration(milliseconds: 4000),
    animation: config.animation ?? const AlwaysStoppedAnimation(1.0),
    shape: config.shape,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    dismissDirection: config.dismissDirection,
    showCloseIcon: config.showCloseIcon,
    closeIconColor: config.closeIconColor,
    actionOverflowThreshold: config.actionOverflowThreshold,
    onVisible: config.onVisible,
    action: action,
  );
}

Widget? _resolveTextOrWidget(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Widget) {
    return value;
  }
  return Text(value.toString());
}
