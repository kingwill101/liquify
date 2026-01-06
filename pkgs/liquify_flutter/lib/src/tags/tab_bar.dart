import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TabBarTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TabBarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildTabBar(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildTabBar(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('tab_bar').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endtab_bar').trim() & tagEnd();
    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'tab_bar',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _TabBarConfig _parseConfig(Evaluator evaluator) {
    final config = _TabBarConfig();
    Object? tabsValue;
    Object? labelsValue;
    Object? onTapValue;
    Object? actionValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'tabs':
          tabsValue = value;
          break;
        case 'labels':
          labelsValue = value;
          break;
        case 'controller':
          if (value is TabController) {
            config.controller = value;
          }
          break;
        case 'isScrollable':
          config.isScrollable = toBool(value);
          break;
        case 'indicatorColor':
          config.indicatorColor = parseColor(value);
          break;
        case 'labelColor':
          config.labelColor = parseColor(value);
          break;
        case 'unselectedLabelColor':
          config.unselectedLabelColor = parseColor(value);
          break;
        case 'labelStyle':
          config.labelStyle = parseTextStyle(value);
          break;
        case 'unselectedLabelStyle':
          config.unselectedLabelStyle = parseTextStyle(value);
          break;
        case 'labelPadding':
          config.labelPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'indicatorSize':
          config.indicatorSize = parseTabBarIndicatorSize(value);
          break;
        case 'indicatorWeight':
          config.indicatorWeight = toDouble(value);
          break;
        case 'indicatorPadding':
          config.indicatorPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'indicator':
          config.indicator = parseDecoration(evaluator, value);
          break;
        case 'dividerColor':
          config.dividerColor = parseColor(value);
          break;
        case 'dividerHeight':
          config.dividerHeight = toDouble(value);
          break;
        case 'padding':
          config.padding = parseEdgeInsetsGeometry(value);
          break;
        case 'length':
          config.length = toInt(value);
          break;
        case 'initialIndex':
          config.initialIndex = toInt(value);
          break;
        case 'onTap':
          onTapValue = value;
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
          handleUnknownArg('tab_bar', name);
          break;
      }
    }

    config.tabs = _resolveTabs(tabsValue, labelsValue);
    final ids = resolveIds(
      evaluator,
      'tab_bar',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'tab_bar',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'tap',
    );
    config.onTap =
        resolveIntActionCallback(
          evaluator,
          onTapValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveIntActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    return config;
  }
}

class _TabBarConfig {
  List<Widget>? tabs;
  TabController? controller;
  bool? isScrollable;
  Color? indicatorColor;
  Color? labelColor;
  Color? unselectedLabelColor;
  TextStyle? labelStyle;
  TextStyle? unselectedLabelStyle;
  EdgeInsetsGeometry? labelPadding;
  TabBarIndicatorSize? indicatorSize;
  double? indicatorWeight;
  EdgeInsetsGeometry? indicatorPadding;
  Decoration? indicator;
  Color? dividerColor;
  double? dividerHeight;
  EdgeInsetsGeometry? padding;
  int? length;
  int? initialIndex;
  ValueChanged<int>? onTap;
  Key? widgetKey;
}

Widget _buildTabBar(_TabBarConfig config, List<Widget> capturedChildren) {
  var tabs =
      config.tabs ??
      (capturedChildren.isEmpty ? const <Widget>[] : capturedChildren);
  if (tabs.isEmpty) {
    tabs = const [Tab(text: 'Tab 1'), Tab(text: 'Tab 2')];
  }
  final tabBar = TabBar(
    key: config.widgetKey,
    controller: config.controller,
    isScrollable: config.isScrollable ?? false,
    indicatorColor: config.indicatorColor,
    labelColor: config.labelColor,
    unselectedLabelColor: config.unselectedLabelColor,
    labelStyle: config.labelStyle,
    unselectedLabelStyle: config.unselectedLabelStyle,
    labelPadding: config.labelPadding,
    indicatorSize: config.indicatorSize,
    indicatorWeight: config.indicatorWeight ?? 2.0,
    indicatorPadding: config.indicatorPadding ?? EdgeInsets.zero,
    indicator: config.indicator,
    dividerColor: config.dividerColor,
    dividerHeight: config.dividerHeight,
    padding: config.padding,
    onTap: config.onTap,
    tabs: tabs,
  );
  if (config.controller != null) {
    return tabBar;
  }
  final length = config.length ?? tabs.length;
  if (length <= 0) {
    return const SizedBox.shrink();
  }
  return DefaultTabController(
    length: length,
    initialIndex: config.initialIndex ?? 0,
    child: tabBar,
  );
}

List<Widget>? _resolveTabs(Object? tabsValue, Object? labelsValue) {
  if (tabsValue != null) {
    if (tabsValue is Iterable) {
      return tabsValue.expand(WidgetTagBase.asWidgets).toList();
    }
    return WidgetTagBase.asWidgets(tabsValue);
  }
  if (labelsValue != null) {
    final labels = parseListOfString(labelsValue) ?? const [];
    return labels.map((label) => Tab(text: label)).toList();
  }
  return null;
}
