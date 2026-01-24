import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TabBarViewTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TabBarViewTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildTabBarView(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildTabBarView(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('tab_bar_view').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endtab_bar_view').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'tab_bar_view',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _TabBarViewConfig _parseConfig(Evaluator evaluator) {
    final config = _TabBarViewConfig();
    Object? childrenValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'children':
          childrenValue = value;
          break;
        case 'controller':
          if (value is TabController) {
            config.controller = value;
          }
          break;
        case 'physics':
          config.physics = parseScrollPhysics(value);
          break;
        case 'viewportFraction':
          config.viewportFraction = toDouble(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'length':
          config.length = toInt(value);
          break;
        case 'initialIndex':
          config.initialIndex = toInt(value);
          break;
        default:
          handleUnknownArg('tab_bar_view', name);
          break;
      }
    }

    config.children = _resolveChildren(childrenValue);
    return config;
  }
}

class _TabBarViewConfig {
  TabController? controller;
  ScrollPhysics? physics;
  double? viewportFraction;
  DragStartBehavior? dragStartBehavior;
  Clip? clipBehavior;
  int? length;
  int? initialIndex;
  List<Widget>? children;
}

Widget _buildTabBarView(
  _TabBarViewConfig config,
  List<Widget> capturedChildren,
) {
  var children =
      config.children ?? (capturedChildren.isEmpty ? const <Widget>[] : capturedChildren);
  if (children.isEmpty) {
    children = const [
      Center(child: Text('Tab 1')),
      Center(child: Text('Tab 2')),
    ];
  }

  final view = TabBarView(
    controller: config.controller,
    physics: config.physics,
    viewportFraction: config.viewportFraction ?? 1.0,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    children: children,
  );

  if (config.controller != null) {
    return view;
  }
  final length = config.length ?? children.length;
  if (length <= 0) {
    return const SizedBox.shrink();
  }
  return DefaultTabController(
    length: length,
    initialIndex: config.initialIndex ?? 0,
    child: view,
  );
}

List<Widget>? _resolveChildren(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Widget) {
    return [value];
  }
  if (value is Iterable) {
    return value.expand(WidgetTagBase.asWidgets).toList();
  }
  return WidgetTagBase.asWidgets(value);
}
