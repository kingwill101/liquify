import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'navigation_props.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class NavigationBarTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  NavigationBarTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final destinations = _captureDestinationsSync(evaluator);
    buffer.write(_buildNavigationBar(config, destinations));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final destinations = await _captureDestinationsAsync(evaluator);
    buffer.write(_buildNavigationBar(config, destinations));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('navigation_bar').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endnavigation_bar').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'navigation_bar',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _NavigationBarConfig _parseConfig(Evaluator evaluator) {
    final config = _NavigationBarConfig();
    Object? actionValue;
    Object? onDestinationSelectedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'selectedIndex':
          config.selectedIndex = toInt(value);
          break;
        case 'onDestinationSelected':
          onDestinationSelectedValue = value;
          break;
        case 'action':
          actionValue = value;
          break;
        case 'indicatorColor':
          config.indicatorColor = parseColor(value);
          break;
        case 'indicatorShape':
          config.indicatorShape = parseShapeBorder(value);
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'height':
          config.height = toDouble(value);
          break;
        case 'labelBehavior':
          config.labelBehavior = parseNavigationDestinationLabelBehavior(value);
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('navigation_bar', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'navigation_bar',
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
      tag: 'navigation_bar',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'selected',
      props: const {},
    );
    final callback =
        resolveIntActionCallback(
          evaluator,
          onDestinationSelectedValue,
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

  List<NavigationDestination> _captureDestinationsSync(Evaluator evaluator) {
    final previous = getNavigationBarSpec(evaluator.context);
    final spec = NavigationBarSpec();
    setNavigationBarSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      evaluator.popBufferValue();
      return spec.destinations;
    } finally {
      setNavigationBarSpec(evaluator.context, previous);
    }
  }

  Future<List<NavigationDestination>> _captureDestinationsAsync(
    Evaluator evaluator,
  ) async {
    final previous = getNavigationBarSpec(evaluator.context);
    final spec = NavigationBarSpec();
    setNavigationBarSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      evaluator.popBufferValue();
      return spec.destinations;
    } finally {
      setNavigationBarSpec(evaluator.context, previous);
    }
  }
}

class NavigationBarDestinationTag extends WidgetTagBase with AsyncTag {
  NavigationBarDestinationTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final destination = _buildDestination(evaluator);
    requireNavigationBarSpec(
      evaluator,
      'navigation_bar_destination',
    ).destinations.add(destination);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final destination = _buildDestination(evaluator);
    requireNavigationBarSpec(
      evaluator,
      'navigation_bar_destination',
    ).destinations.add(destination);
  }

  NavigationDestination _buildDestination(Evaluator evaluator) {
    Widget? icon;
    Widget? selectedIcon;
    String label = '';
    String? tooltip;
    bool? enabled;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
          label = value?.toString() ?? '';
          break;
        case 'icon':
          icon = resolveIconWidget(value);
          break;
        case 'selectedIcon':
          selectedIcon = resolveIconWidget(value);
          break;
        case 'tooltip':
          tooltip = value?.toString();
          break;
        case 'enabled':
          enabled = toBool(value);
          break;
        default:
          handleUnknownArg('navigation_bar_destination', name);
          break;
      }
    }

    return NavigationDestination(
      icon: icon ?? const SizedBox.shrink(),
      selectedIcon: selectedIcon,
      label: label,
      tooltip: tooltip,
      enabled: enabled ?? true,
    );
  }
}

class _NavigationBarConfig {
  int? selectedIndex;
  ValueChanged<int>? onDestinationSelected;
  Color? indicatorColor;
  ShapeBorder? indicatorShape;
  Color? backgroundColor;
  double? elevation;
  double? height;
  NavigationDestinationLabelBehavior? labelBehavior;
  Key? widgetKey;
}

Widget _buildNavigationBar(
  _NavigationBarConfig config,
  List<NavigationDestination> destinations,
) {
  if (destinations.isEmpty) {
    return const SizedBox.shrink();
  }
  return NavigationBar(
    key: config.widgetKey,
    selectedIndex: config.selectedIndex ?? 0,
    onDestinationSelected: config.onDestinationSelected,
    backgroundColor: config.backgroundColor,
    elevation: config.elevation,
    height: config.height,
    indicatorColor: config.indicatorColor,
    indicatorShape: config.indicatorShape,
    labelBehavior: config.labelBehavior,
    destinations: destinations,
  );
}
