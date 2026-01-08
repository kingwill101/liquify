import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'navigation_props.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class BottomNavTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  BottomNavTag(this.tagName, super.content, super.filters);

  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final items = _captureItemsSync(evaluator);
    buffer.write(_buildBottomNav(config, items));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final items = await _captureItemsAsync(evaluator);
    buffer.write(_buildBottomNav(config, items));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string(tagName).trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('end$tagName').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        tagName,
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _BottomNavConfig _parseConfig(Evaluator evaluator) {
    final config = _BottomNavConfig();
    Object? actionValue;
    Object? onTapValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'currentIndex':
        case 'selectedIndex':
          config.currentIndex = toInt(value);
          break;
        case 'type':
          config.type = parseBottomNavigationBarType(value);
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'iconSize':
          config.iconSize = toDouble(value);
          break;
        case 'selectedItemColor':
          config.selectedItemColor = parseColor(value);
          break;
        case 'unselectedItemColor':
          config.unselectedItemColor = parseColor(value);
          break;
        case 'selectedFontSize':
          config.selectedFontSize = toDouble(value);
          break;
        case 'unselectedFontSize':
          config.unselectedFontSize = toDouble(value);
          break;
        case 'selectedLabelStyle':
          config.selectedLabelStyle = parseTextStyle(value);
          break;
        case 'unselectedLabelStyle':
          config.unselectedLabelStyle = parseTextStyle(value);
          break;
        case 'showSelectedLabels':
          config.showSelectedLabels = toBool(value);
          break;
        case 'showUnselectedLabels':
          config.showUnselectedLabels = toBool(value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'mouseCursor':
          config.mouseCursor = parseMouseCursor(value);
          break;
        case 'landscapeLayout':
          config.landscapeLayout = parseBottomNavigationBarLandscapeLayout(value);
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
          handleUnknownArg(tagName, name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      tagName,
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
      tag: 'bottom_nav',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'tap',
      props: const {},
    );
    final callback =
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
    config.onTap = callback == null
        ? null
        : (index) {
            baseEvent['index'] = index;
            callback(index);
          };
    return config;
  }

  List<BottomNavigationBarItem> _captureItemsSync(Evaluator evaluator) {
    final previous = getBottomNavSpec(evaluator.context);
    final spec = BottomNavSpec();
    setBottomNavSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      evaluator.popBufferValue();
      return spec.items;
    } finally {
      setBottomNavSpec(evaluator.context, previous);
    }
  }

  Future<List<BottomNavigationBarItem>> _captureItemsAsync(
    Evaluator evaluator,
  ) async {
    final previous = getBottomNavSpec(evaluator.context);
    final spec = BottomNavSpec();
    setBottomNavSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      evaluator.popBufferValue();
      return spec.items;
    } finally {
      setBottomNavSpec(evaluator.context, previous);
    }
  }
}

class BottomNavItemTag extends WidgetTagBase with AsyncTag {
  BottomNavItemTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final item = _buildItem(evaluator);
    requireBottomNavSpec(evaluator, 'bottom_nav_item').items.add(item);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final item = _buildItem(evaluator);
    requireBottomNavSpec(evaluator, 'bottom_nav_item').items.add(item);
  }

  BottomNavigationBarItem _buildItem(Evaluator evaluator) {
    String? label;
    Widget? icon;
    Widget? activeIcon;
    Color? backgroundColor;
    String? tooltip;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
          label = value?.toString();
          break;
        case 'icon':
          icon = resolveIconWidget(value);
          break;
        case 'activeIcon':
          activeIcon = resolveIconWidget(value);
          break;
        case 'backgroundColor':
          backgroundColor = parseColor(value);
          break;
        case 'tooltip':
          tooltip = value?.toString();
          break;
        default:
          handleUnknownArg('bottom_nav_item', name);
          break;
      }
    }
    return BottomNavigationBarItem(
      icon: icon ?? const SizedBox.shrink(),
      activeIcon: activeIcon,
      label: label ?? '',
      backgroundColor: backgroundColor,
      tooltip: tooltip,
    );
  }
}

class _BottomNavConfig {
  int? currentIndex;
  BottomNavigationBarType? type;
  Color? backgroundColor;
  double? elevation;
  double? iconSize;
  Color? selectedItemColor;
  Color? unselectedItemColor;
  double? selectedFontSize;
  double? unselectedFontSize;
  TextStyle? selectedLabelStyle;
  TextStyle? unselectedLabelStyle;
  bool? showSelectedLabels;
  bool? showUnselectedLabels;
  bool? enableFeedback;
  MouseCursor? mouseCursor;
  BottomNavigationBarLandscapeLayout? landscapeLayout;
  ValueChanged<int>? onTap;
  Key? widgetKey;
}

Widget _buildBottomNav(
  _BottomNavConfig config,
  List<BottomNavigationBarItem> items,
) {
  if (items.isEmpty) {
    return const SizedBox.shrink();
  }
  return BottomNavigationBar(
    key: config.widgetKey,
    items: items,
    currentIndex: config.currentIndex ?? 0,
    type: config.type,
    backgroundColor: config.backgroundColor,
    elevation: config.elevation,
    iconSize: config.iconSize ?? 24,
    selectedItemColor: config.selectedItemColor,
    unselectedItemColor: config.unselectedItemColor,
    selectedFontSize: config.selectedFontSize ?? 14,
    unselectedFontSize: config.unselectedFontSize ?? 12,
    selectedLabelStyle: config.selectedLabelStyle,
    unselectedLabelStyle: config.unselectedLabelStyle,
    showSelectedLabels: config.showSelectedLabels,
    showUnselectedLabels: config.showUnselectedLabels,
    enableFeedback: config.enableFeedback,
    mouseCursor: config.mouseCursor,
    landscapeLayout: config.landscapeLayout,
    onTap: config.onTap,
  );
}
