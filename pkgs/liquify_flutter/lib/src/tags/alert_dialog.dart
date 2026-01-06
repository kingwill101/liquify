import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AlertDialogTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  AlertDialogTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildAlertDialog(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildAlertDialog(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('alert_dialog').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endalert_dialog').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'alert_dialog',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _AlertDialogConfig _parseConfig(Evaluator evaluator) {
    final config = _AlertDialogConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'title':
          config.title = _resolveTextOrWidget(value);
          break;
        case 'content':
          config.content = _resolveTextOrWidget(value);
          break;
        case 'actions':
          config.actions = _resolveWidgetList(value);
          break;
        case 'icon':
          config.icon = value is Widget ? value : resolveIconWidget(value);
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'shadowColor':
          config.shadowColor = parseColor(value);
          break;
        case 'surfaceTintColor':
          config.surfaceTintColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'scrollable':
          config.scrollable = toBool(value);
          break;
        case 'actionsAlignment':
          config.actionsAlignment = parseMainAxisAlignment(value);
          break;
        case 'actionsPadding':
          config.actionsPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'contentPadding':
          config.contentPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'titlePadding':
          config.titlePadding = parseEdgeInsetsGeometry(value);
          break;
        case 'iconPadding':
          config.iconPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'insetPadding':
          config.insetPadding = parseEdgeInsetsGeometry(value) as EdgeInsets?;
          break;
        case 'titleTextStyle':
          config.titleTextStyle = parseTextStyle(value);
          break;
        case 'contentTextStyle':
          config.contentTextStyle = parseTextStyle(value);
          break;
        default:
          handleUnknownArg('alert_dialog', name);
          break;
      }
    }
    return config;
  }
}

class _AlertDialogConfig {
  Widget? title;
  Widget? content;
  List<Widget>? actions;
  Widget? icon;
  Color? backgroundColor;
  Color? shadowColor;
  Color? surfaceTintColor;
  double? elevation;
  ShapeBorder? shape;
  Clip? clipBehavior;
  bool? scrollable;
  MainAxisAlignment? actionsAlignment;
  EdgeInsetsGeometry? actionsPadding;
  EdgeInsetsGeometry? contentPadding;
  EdgeInsetsGeometry? titlePadding;
  EdgeInsetsGeometry? iconPadding;
  EdgeInsets? insetPadding;
  TextStyle? titleTextStyle;
  TextStyle? contentTextStyle;
}

Widget _buildAlertDialog(_AlertDialogConfig config, List<Widget> children) {
  final title = config.title;
  Widget? content = config.content;
  List<Widget>? actions = config.actions;
  if (content == null && children.isNotEmpty) {
    content = wrapChildren(children);
  } else if (content != null && actions == null && children.isNotEmpty) {
    actions = children;
  }
  return AlertDialog(
    icon: config.icon,
    title: title,
    content: content,
    actions: actions,
    backgroundColor: config.backgroundColor,
    shadowColor: config.shadowColor,
    surfaceTintColor: config.surfaceTintColor,
    elevation: config.elevation,
    shape: config.shape,
    clipBehavior: config.clipBehavior,
    scrollable: config.scrollable ?? false,
    actionsAlignment: config.actionsAlignment,
    actionsPadding: config.actionsPadding,
    contentPadding: config.contentPadding,
    titlePadding: config.titlePadding,
    iconPadding: config.iconPadding,
    insetPadding: config.insetPadding,
    titleTextStyle: config.titleTextStyle,
    contentTextStyle: config.contentTextStyle,
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

List<Widget>? _resolveWidgetList(Object? value) {
  if (value == null) {
    return null;
  }
  return WidgetTagBase.asWidgets(value);
}
