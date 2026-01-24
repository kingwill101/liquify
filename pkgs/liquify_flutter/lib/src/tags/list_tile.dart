import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ListTileTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ListTileTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildListTile(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildListTile(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('list_tile').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endlist_tile').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'list_tile',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ListTileConfig _parseConfig(Evaluator evaluator) {
    final config = _ListTileConfig();
    Object? actionValue;
    Object? onTapValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'title':
          config.title = value?.toString();
          break;
        case 'subtitle':
          config.subtitle = value?.toString();
          break;
        case 'leading':
          config.leading = resolveIconWidget(value);
          break;
        case 'trailing':
          config.trailing = resolveIconWidget(value);
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
        case 'isThreeLine':
          config.isThreeLine = toBool(value);
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
        case 'selectedColor':
          config.selectedColor = parseColor(value);
          break;
        case 'textColor':
          config.textColor = parseColor(value);
          break;
        case 'iconColor':
          config.iconColor = parseColor(value);
          break;
        case 'titleTextStyle':
          config.titleTextStyle = parseTextStyle(value);
          break;
        case 'subtitleTextStyle':
          config.subtitleTextStyle = parseTextStyle(value);
          break;
        case 'leadingAndTrailingTextStyle':
          config.leadingAndTrailingTextStyle = parseTextStyle(value);
          break;
        case 'minLeadingWidth':
          config.minLeadingWidth = toDouble(value);
          break;
        case 'horizontalTitleGap':
          config.horizontalTitleGap = toDouble(value);
          break;
        case 'minVerticalPadding':
          config.minVerticalPadding = toDouble(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onTap':
          onTapValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('list_tile', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'list_tile',
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
      tag: 'list_tile',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'tap',
      props: {
        'title': config.title,
        'subtitle': config.subtitle,
      },
    );
    config.onTap =
        resolveActionCallback(
              evaluator,
              onTapValue,
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

  List<Widget> _captureChildrenSync(Evaluator evaluator) {
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    final captured = evaluator.popBufferValue();
    return _asWidgets(captured);
  }

  Future<List<Widget>> _captureChildrenAsync(Evaluator evaluator) async {
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    final captured = evaluator.popBufferValue();
    return _asWidgets(captured);
  }
}

class _ListTileConfig {
  String? title;
  String? subtitle;
  Widget? leading;
  Widget? trailing;
  bool? dense;
  bool? enabled;
  bool? selected;
  bool? isThreeLine;
  EdgeInsetsGeometry? contentPadding;
  Color? tileColor;
  Color? selectedTileColor;
  Color? selectedColor;
  Color? textColor;
  Color? iconColor;
  TextStyle? titleTextStyle;
  TextStyle? subtitleTextStyle;
  TextStyle? leadingAndTrailingTextStyle;
  double? minLeadingWidth;
  double? horizontalTitleGap;
  double? minVerticalPadding;
  ShapeBorder? shape;
  VoidCallback? onTap;
  Key? widgetKey;
}

Widget _buildListTile(_ListTileConfig config, List<Widget> children) {
  Widget? title;
  if (config.title != null && config.title!.trim().isNotEmpty) {
    title = Text(config.title!);
  } else if (children.isNotEmpty) {
    title = wrapChildren(children);
  }
  return ListTile(
    key: config.widgetKey,
    title: title,
    subtitle: config.subtitle == null ? null : Text(config.subtitle!),
    leading: config.leading,
    trailing: config.trailing,
    dense: config.dense,
    enabled: config.enabled ?? true,
    selected: config.selected ?? false,
    isThreeLine: config.isThreeLine ?? false,
    contentPadding: config.contentPadding,
    tileColor: config.tileColor,
    selectedTileColor: config.selectedTileColor,
    selectedColor: config.selectedColor,
    textColor: config.textColor,
    iconColor: config.iconColor,
    titleTextStyle: config.titleTextStyle,
    subtitleTextStyle: config.subtitleTextStyle,
    leadingAndTrailingTextStyle: config.leadingAndTrailingTextStyle,
    minLeadingWidth: config.minLeadingWidth,
    horizontalTitleGap: config.horizontalTitleGap,
    minVerticalPadding: config.minVerticalPadding,
    shape: config.shape,
    onTap: config.onTap,
  );
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
