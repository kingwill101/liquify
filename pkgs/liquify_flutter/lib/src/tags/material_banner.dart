import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class MaterialBannerTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  MaterialBannerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildBanner(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildBanner(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('material_banner').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endmaterial_banner').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'material_banner',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _MaterialBannerConfig _parseConfig(Evaluator evaluator) {
    final config = _MaterialBannerConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'content':
          config.content = _resolveTextOrWidget(value);
          break;
        case 'actions':
          config.actions = _resolveWidgetList(value);
          break;
        case 'leading':
          config.leading = value is Widget ? value : resolveIconWidget(value);
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'padding':
          config.padding = parseEdgeInsetsGeometry(value);
          break;
        case 'leadingPadding':
          config.leadingPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'contentTextStyle':
          config.contentTextStyle = parseTextStyle(value);
          break;
        case 'forceActionsBelow':
          config.forceActionsBelow = toBool(value);
          break;
        case 'overflowAlignment':
          if (value is OverflowBarAlignment) {
            config.overflowAlignment = value;
          }
          break;
        default:
          handleUnknownArg('material_banner', name);
          break;
      }
    }
    return config;
  }
}

class _MaterialBannerConfig {
  Widget? content;
  List<Widget>? actions;
  Widget? leading;
  Color? backgroundColor;
  EdgeInsetsGeometry? padding;
  EdgeInsetsGeometry? leadingPadding;
  TextStyle? contentTextStyle;
  bool? forceActionsBelow;
  OverflowBarAlignment? overflowAlignment;
}

Widget _buildBanner(_MaterialBannerConfig config, List<Widget> children) {
  Widget? content = config.content;
  List<Widget>? actions = config.actions;
  if (content == null && children.isNotEmpty) {
    content = children.first;
    if (children.length > 1) {
      actions = children.sublist(1);
    }
  } else if (content != null && actions == null && children.isNotEmpty) {
    actions = children;
  }
  actions ??= const [];
  if (actions.isEmpty) {
    actions = const [SizedBox.shrink()];
  }
  return MaterialBanner(
    content: content ?? const SizedBox.shrink(),
    actions: actions,
    leading: config.leading,
    backgroundColor: config.backgroundColor,
    padding: config.padding,
    leadingPadding: config.leadingPadding,
    contentTextStyle: config.contentTextStyle,
    forceActionsBelow: config.forceActionsBelow ?? false,
    overflowAlignment: config.overflowAlignment ?? OverflowBarAlignment.end,
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
