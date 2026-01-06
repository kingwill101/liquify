import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class NavigationDrawerTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  NavigationDrawerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildDrawer(evaluator, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildDrawer(evaluator, config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('navigation_drawer').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endnavigation_drawer').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'navigation_drawer',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _NavigationDrawerConfig _parseConfig(Evaluator evaluator) {
    final config = _NavigationDrawerConfig();
    Object? actionValue;
    Object? onDestinationSelectedValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    final namedValues = <String, Object?>{};
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
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'indicatorColor':
          config.indicatorColor = parseColor(value);
          break;
        case 'indicatorShape':
          config.indicatorShape = parseShapeBorder(value);
          break;
        case 'tilePadding':
          namedValues[name] = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('navigation_drawer', name);
          break;
      }
    }

    config.tilePadding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'tilePadding',
      parser: parseEdgeInsetsGeometry,
    );

    final resolvedId = resolveWidgetId(
      evaluator,
      'navigation_drawer',
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
      tag: 'navigation_drawer',
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
}

class NavigationDrawerDestinationTag extends WidgetTagBase with AsyncTag {
  NavigationDrawerDestinationTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    buffer.write(_buildDestination(evaluator));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    buffer.write(_buildDestination(evaluator));
  }

  NavigationDrawerDestination _buildDestination(Evaluator evaluator) {
    Widget? icon;
    Widget? selectedIcon;
    String label = '';
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
        default:
          handleUnknownArg('navigation_drawer_destination', name);
          break;
      }
    }
    return NavigationDrawerDestination(
      icon: icon ?? const SizedBox.shrink(),
      selectedIcon: selectedIcon,
      label: Text(label),
    );
  }
}

class DrawerHeaderTag extends WidgetTagBase with AsyncTag {
  DrawerHeaderTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildHeader(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildHeader(config, children));
  }

  _DrawerHeaderConfig _parseConfig(Evaluator evaluator) {
    final config = _DrawerHeaderConfig();
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'decoration':
          config.decoration = parseDecoration(evaluator, value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'margin':
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('drawer_header', name);
          break;
      }
    }
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    config.margin = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'margin',
      parser: parseEdgeInsetsGeometry,
    );
    return config;
  }
}

class _NavigationDrawerConfig {
  int? selectedIndex;
  ValueChanged<int>? onDestinationSelected;
  Color? backgroundColor;
  Color? indicatorColor;
  ShapeBorder? indicatorShape;
  EdgeInsetsGeometry? tilePadding;
  Key? widgetKey;
}

Widget _buildDrawer(
  Evaluator evaluator,
  _NavigationDrawerConfig config,
  List<Widget> children,
) {
  return NavigationDrawer(
    key: config.widgetKey,
    selectedIndex: config.selectedIndex,
    onDestinationSelected: config.onDestinationSelected,
    backgroundColor: config.backgroundColor,
    indicatorColor: config.indicatorColor,
    indicatorShape: config.indicatorShape,
    tilePadding:
        config.tilePadding ?? const EdgeInsets.symmetric(horizontal: 12.0),
    children: children,
  );
}

class _DrawerHeaderConfig {
  Decoration? decoration;
  EdgeInsetsGeometry? padding;
  EdgeInsetsGeometry? margin;
}

Widget _buildHeader(_DrawerHeaderConfig config, List<Widget> children) {
  return DrawerHeader(
    decoration: config.decoration,
    padding: config.padding ?? const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
    margin: config.margin ?? const EdgeInsets.only(bottom: 8.0),
    child: wrapChildren(children),
  );
}
