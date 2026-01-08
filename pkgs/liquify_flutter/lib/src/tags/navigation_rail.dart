import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'navigation_props.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class NavigationRailTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  NavigationRailTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final destinations = _captureDestinationsSync(evaluator);
    buffer.write(_buildNavigationRail(config, destinations));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final destinations = await _captureDestinationsAsync(evaluator);
    buffer.write(_buildNavigationRail(config, destinations));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('navigation_rail').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endnavigation_rail').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'navigation_rail',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _NavigationRailConfig _parseConfig(Evaluator evaluator) {
    final config = _NavigationRailConfig();
    Object? actionValue;
    Object? onSelectValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'selectedIndex':
        case 'currentIndex':
          config.selectedIndex = toInt(value);
          break;
        case 'labelType':
          config.labelType = parseNavigationRailLabelType(value);
          break;
        case 'groupAlignment':
          config.groupAlignment = toDouble(value);
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'leading':
          if (value is Widget) {
            config.leading = value;
          }
          break;
        case 'trailing':
          if (value is Widget) {
            config.trailing = value;
          }
          break;
        case 'minWidth':
          config.minWidth = toDouble(value);
          break;
        case 'minExtendedWidth':
          config.minExtendedWidth = toDouble(value);
          break;
        case 'extended':
          config.extended = toBool(value);
          break;
        case 'useIndicator':
          config.useIndicator = toBool(value);
          break;
        case 'indicatorColor':
          config.indicatorColor = parseColor(value);
          break;
        case 'indicatorShape':
          config.indicatorShape = parseShapeBorder(value);
          break;
        case 'selectedIconTheme':
          config.selectedIconTheme = parseIconThemeData(value) ??
              (value is IconThemeData ? value : null);
          break;
        case 'unselectedIconTheme':
          config.unselectedIconTheme = parseIconThemeData(value) ??
              (value is IconThemeData ? value : null);
          break;
        case 'selectedLabelTextStyle':
          config.selectedLabelTextStyle = parseTextStyle(value);
          break;
        case 'unselectedLabelTextStyle':
          config.unselectedLabelTextStyle = parseTextStyle(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onDestinationSelected':
        case 'onSelected':
          onSelectValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('navigation_rail', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'navigation_rail',
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
      tag: 'navigation_rail',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'changed',
      props: const {},
    );
    final callback =
        resolveIntActionCallback(
              evaluator,
              onSelectValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveIntActionCallback(
              evaluator,
              actionValue,
              event: baseEvent,
              actionValue: actionName,
            );
    config.onDestinationSelected = callback == null
        ? null
        : (index) {
            baseEvent['index'] = index;
            callback(index);
          };
    return config;
  }

  List<NavigationRailDestination> _captureDestinationsSync(
    Evaluator evaluator,
  ) {
    final previous = getNavigationRailSpec(evaluator.context);
    final spec = NavigationRailSpec();
    setNavigationRailSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      evaluator.popBufferValue();
      return spec.destinations;
    } finally {
      setNavigationRailSpec(evaluator.context, previous);
    }
  }

  Future<List<NavigationRailDestination>> _captureDestinationsAsync(
    Evaluator evaluator,
  ) async {
    final previous = getNavigationRailSpec(evaluator.context);
    final spec = NavigationRailSpec();
    setNavigationRailSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      evaluator.popBufferValue();
      return spec.destinations;
    } finally {
      setNavigationRailSpec(evaluator.context, previous);
    }
  }
}

class NavigationDestinationTag extends WidgetTagBase with AsyncTag {
  NavigationDestinationTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final destination = _buildDestination(evaluator);
    requireNavigationRailSpec(evaluator, 'navigation_destination')
        .destinations
        .add(destination);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final destination = _buildDestination(evaluator);
    requireNavigationRailSpec(evaluator, 'navigation_destination')
        .destinations
        .add(destination);
  }

  NavigationRailDestination _buildDestination(Evaluator evaluator) {
    Widget? icon;
    Widget? selectedIcon;
    Widget? label;
    EdgeInsetsGeometry? padding;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
          if (value is Widget) {
            label = value;
          } else {
            label = Text(value?.toString() ?? '');
          }
          break;
        case 'icon':
          icon = resolveIconWidget(value);
          break;
        case 'selectedIcon':
          selectedIcon = resolveIconWidget(value);
          break;
        case 'padding':
          padding = parseEdgeInsetsGeometry(value);
          break;
        default:
          handleUnknownArg('navigation_destination', name);
          break;
      }
    }
    return NavigationRailDestination(
      icon: icon ?? const SizedBox.shrink(),
      selectedIcon: selectedIcon,
      label: label ?? const SizedBox.shrink(),
      padding: padding,
    );
  }
}

class _NavigationRailConfig {
  int? selectedIndex;
  NavigationRailLabelType? labelType;
  double? groupAlignment;
  Color? backgroundColor;
  double? elevation;
  Widget? leading;
  Widget? trailing;
  double? minWidth;
  double? minExtendedWidth;
  bool? extended;
  bool? useIndicator;
  Color? indicatorColor;
  ShapeBorder? indicatorShape;
  IconThemeData? selectedIconTheme;
  IconThemeData? unselectedIconTheme;
  TextStyle? selectedLabelTextStyle;
  TextStyle? unselectedLabelTextStyle;
  ValueChanged<int>? onDestinationSelected;
  Key? widgetKey;
}

Widget _buildNavigationRail(
  _NavigationRailConfig config,
  List<NavigationRailDestination> destinations,
) {
  if (destinations.isEmpty) {
    return const SizedBox.shrink();
  }
  var labelType = config.labelType;
  if (config.extended == true &&
      labelType != null &&
      labelType != NavigationRailLabelType.none) {
    labelType = NavigationRailLabelType.none;
  }
  return NavigationRail(
    key: config.widgetKey,
    selectedIndex: config.selectedIndex ?? 0,
    onDestinationSelected: config.onDestinationSelected,
    labelType: labelType,
    groupAlignment: config.groupAlignment,
    backgroundColor: config.backgroundColor,
    elevation: config.elevation,
    leading: config.leading,
    trailing: config.trailing,
    minWidth: config.minWidth,
    minExtendedWidth: config.minExtendedWidth,
    extended: config.extended ?? false,
    useIndicator: config.useIndicator,
    indicatorColor: config.indicatorColor,
    indicatorShape: config.indicatorShape,
    selectedIconTheme: config.selectedIconTheme,
    unselectedIconTheme: config.unselectedIconTheme,
    selectedLabelTextStyle: config.selectedLabelTextStyle,
    unselectedLabelTextStyle: config.unselectedLabelTextStyle,
    destinations: destinations,
  );
}
