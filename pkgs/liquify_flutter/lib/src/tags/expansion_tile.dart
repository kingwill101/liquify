import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ExpansionTileTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ExpansionTileTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildExpansionTile(evaluator, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildExpansionTile(evaluator, config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('expansion_tile').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endexpansion_tile').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'expansion_tile',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ExpansionTileConfig _parseConfig(Evaluator evaluator) {
    final config = _ExpansionTileConfig();
    Object? titleValue;
    Object? subtitleValue;
    Object? leadingValue;
    Object? trailingValue;
    Object? onExpansionChangedValue;
    Object? actionValue;
    String? widgetIdValue;
    String? widgetKeyValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'title':
        case 'label':
        case 'text':
        case 'value':
          titleValue = value;
          break;
        case 'subtitle':
          subtitleValue = value;
          break;
        case 'leading':
          leadingValue = value;
          break;
        case 'trailing':
          trailingValue = value;
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'collapsedBackgroundColor':
          config.collapsedBackgroundColor = parseColor(value);
          break;
        case 'textColor':
          config.textColor = parseColor(value);
          break;
        case 'collapsedTextColor':
          config.collapsedTextColor = parseColor(value);
          break;
        case 'iconColor':
          config.iconColor = parseColor(value);
          break;
        case 'collapsedIconColor':
          config.collapsedIconColor = parseColor(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'collapsedShape':
          config.collapsedShape = parseShapeBorder(value);
          break;
        case 'tilePadding':
          config.tilePadding = parseEdgeInsetsGeometry(value);
          break;
        case 'childrenPadding':
          config.childrenPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'expandedAlignment':
          final alignment = parseAlignmentGeometry(value);
          if (alignment is Alignment) {
            config.expandedAlignment = alignment;
          }
          break;
        case 'expandedCrossAxisAlignment':
          config.expandedCrossAxisAlignment = parseCrossAxisAlignment(value);
          break;
        case 'controlAffinity':
          config.controlAffinity = parseListTileControlAffinity(value);
          break;
        case 'initiallyExpanded':
          config.initiallyExpanded = toBool(value);
          break;
        case 'maintainState':
          config.maintainState = toBool(value);
          break;
        case 'dense':
          config.dense = toBool(value);
          break;
        case 'visualDensity':
          config.visualDensity = parseVisualDensity(value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'onExpansionChanged':
          onExpansionChangedValue = value;
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
          handleUnknownArg('expansion_tile', name);
          break;
      }
    }

    config.title =
        resolveTextWidget(titleValue) ?? resolveIconWidget(titleValue);
    config.subtitle = resolveTextWidget(subtitleValue);
    config.leading = leadingValue is Widget
        ? leadingValue
        : resolveIconWidget(leadingValue);
    config.trailing = trailingValue is Widget
        ? trailingValue
        : resolveIconWidget(trailingValue);

    config.title ??=
        resolveTextWidget(evaluatePositionalValue(evaluator, content)) ??
        const Text('');

    final ids = resolveIds(
      evaluator,
      'expansion_tile',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;

    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'expansion_tile',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'expanded',
    );
    config.onExpansionChanged =
        resolveBoolActionCallback(
          evaluator,
          onExpansionChangedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveBoolActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );

    return config;
  }
}

class _ExpansionTileConfig {
  Widget? title;
  Widget? subtitle;
  Widget? leading;
  Widget? trailing;
  Color? backgroundColor;
  Color? collapsedBackgroundColor;
  Color? textColor;
  Color? collapsedTextColor;
  Color? iconColor;
  Color? collapsedIconColor;
  ShapeBorder? shape;
  ShapeBorder? collapsedShape;
  EdgeInsetsGeometry? tilePadding;
  EdgeInsetsGeometry? childrenPadding;
  Alignment? expandedAlignment;
  CrossAxisAlignment? expandedCrossAxisAlignment;
  ListTileControlAffinity? controlAffinity;
  bool? initiallyExpanded;
  bool? maintainState;
  bool? dense;
  VisualDensity? visualDensity;
  bool? enableFeedback;
  ValueChanged<bool>? onExpansionChanged;
  Key? widgetKey;
}

Widget _buildExpansionTile(
  Evaluator evaluator,
  _ExpansionTileConfig config,
  List<Widget> children,
) {
  final resolvedChildren = children;
  return ExpansionTile(
    key: config.widgetKey,
    title: config.title ?? const Text(''),
    subtitle: config.subtitle,
    leading: config.leading,
    trailing: config.trailing,
    backgroundColor: config.backgroundColor,
    collapsedBackgroundColor: config.collapsedBackgroundColor,
    textColor: config.textColor,
    collapsedTextColor: config.collapsedTextColor,
    iconColor: config.iconColor,
    collapsedIconColor: config.collapsedIconColor,
    shape: config.shape,
    collapsedShape: config.collapsedShape,
    tilePadding: config.tilePadding,
    childrenPadding: config.childrenPadding,
    expandedAlignment: config.expandedAlignment,
    expandedCrossAxisAlignment: config.expandedCrossAxisAlignment,
    controlAffinity: config.controlAffinity,
    initiallyExpanded: config.initiallyExpanded ?? false,
    maintainState: config.maintainState ?? false,
    dense: config.dense,
    visualDensity: config.visualDensity,
    enableFeedback: config.enableFeedback,
    onExpansionChanged: config.onExpansionChanged,
    children: resolvedChildren,
  );
}
