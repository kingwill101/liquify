import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ListViewBuilderTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ListViewBuilderTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final items = _resolveItems(config.items);
    final built = _buildItems(evaluator, config, items);
    buffer.write(_buildListView(config, built, items.length));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final items = _resolveItems(config.items);
    final built = _buildItems(evaluator, config, items);
    buffer.write(_buildListView(config, built, items.length));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('list_view_builder').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endlist_view_builder').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'list_view_builder',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ListViewBuilderConfig _parseConfig(Evaluator evaluator) {
    final config = _ListViewBuilderConfig();
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'items':
          config.items = evaluator.evaluate(arg.value);
          break;
        case 'itemName':
          config.itemName = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'indexName':
          config.indexName = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'gap':
          config.gap = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'scrollDirection':
        case 'direction':
        case 'axis':
          config.scrollDirection = parseAxis(evaluator.evaluate(arg.value));
          break;
        case 'reverse':
          config.reverse = toBool(evaluator.evaluate(arg.value));
          break;
        case 'controller':
          final value = evaluator.evaluate(arg.value);
          if (value is ScrollController) {
            config.controller = value;
          }
          break;
        case 'primary':
          config.primary = toBool(evaluator.evaluate(arg.value));
          break;
        case 'physics':
          config.physics = parseScrollPhysics(evaluator.evaluate(arg.value));
          break;
        case 'shrinkWrap':
          config.shrinkWrap = toBool(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'separator':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'itemExtent':
          config.itemExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'itemExtentBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ItemExtentBuilder) {
            config.itemExtentBuilder = value;
          }
          break;
        case 'prototypeItem':
          final value = evaluator.evaluate(arg.value);
          if (value is Widget) {
            config.prototypeItem = value;
          }
          break;
        case 'addAutomaticKeepAlives':
          config.addAutomaticKeepAlives = toBool(evaluator.evaluate(arg.value));
          break;
        case 'addRepaintBoundaries':
          config.addRepaintBoundaries = toBool(evaluator.evaluate(arg.value));
          break;
        case 'addSemanticIndexes':
          config.addSemanticIndexes = toBool(evaluator.evaluate(arg.value));
          break;
        case 'cacheExtent':
          config.cacheExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'semanticChildCount':
          config.semanticChildCount = toInt(evaluator.evaluate(arg.value));
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior =
              parseDragStartBehavior(evaluator.evaluate(arg.value));
          break;
        case 'keyboardDismissBehavior':
          config.keyboardDismissBehavior =
              parseScrollViewKeyboardDismissBehavior(
                evaluator.evaluate(arg.value),
              );
          break;
        case 'restorationId':
          config.restorationId = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'hitTestBehavior':
          config.hitTestBehavior =
              parseHitTestBehavior(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('list_view_builder', name);
          break;
      }
    }
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    config.separator = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'separator',
      parser: (value) => value is Widget ? value : null,
    );
    return config;
  }

  List<Widget> _buildItems(
    Evaluator evaluator,
    _ListViewBuilderConfig config,
    List<Object?> items,
  ) {
    if (items.isEmpty) {
      return const [];
    }
    final itemName =
        config.itemName?.trim().isNotEmpty == true ? config.itemName! : 'item';
    final indexName =
        config.indexName?.trim().isNotEmpty == true ? config.indexName! : 'index';
    final axis = config.scrollDirection ?? Axis.vertical;
    final padding = config.gap == null || config.gap == 0
        ? null
        : EdgeInsets.only(
            right: axis == Axis.horizontal ? config.gap! : 0,
            bottom: axis == Axis.vertical ? config.gap! : 0,
          );
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final scope = pushPropertyScope(evaluator.context);
      evaluator.context.pushScope();
      evaluator.context.setVariable(itemName, items[i]);
      evaluator.context.setVariable(indexName, i);
      evaluator.startBlockCapture();
      try {
        evaluator.evaluateNodes(body);
        final captured = evaluator.popBufferValue();
        final children = WidgetTagBase.asWidgets(captured);
        if (children.isEmpty) {
          continue;
        }
        final widget = children.length == 1 ? children.first : wrapChildren(children);
        widgets.add(padding == null ? widget : Padding(padding: padding, child: widget));
      } finally {
        evaluator.context.popScope();
        popPropertyScope(evaluator.context, scope);
      }
    }
    return widgets;
  }
}

class _ListViewBuilderConfig {
  Object? items;
  String? itemName;
  String? indexName;
  double? gap;
  Axis? scrollDirection;
  bool? reverse;
  ScrollController? controller;
  bool? primary;
  ScrollPhysics? physics;
  bool? shrinkWrap;
  EdgeInsetsGeometry? padding;
  Widget? separator;
  double? itemExtent;
  ItemExtentBuilder? itemExtentBuilder;
  Widget? prototypeItem;
  bool? addAutomaticKeepAlives;
  bool? addRepaintBoundaries;
  bool? addSemanticIndexes;
  double? cacheExtent;
  int? semanticChildCount;
  DragStartBehavior? dragStartBehavior;
  ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  String? restorationId;
  Clip? clipBehavior;
  HitTestBehavior? hitTestBehavior;
}

ListView _buildListView(
  _ListViewBuilderConfig config,
  List<Widget> children,
  int itemCount,
) {
  final semanticChildCount = config.semanticChildCount ?? itemCount;
  if (config.separator != null) {
    return ListView.separated(
      scrollDirection: config.scrollDirection ?? Axis.vertical,
      reverse: config.reverse ?? false,
      controller: config.controller,
      primary: config.primary,
      physics: config.physics,
      shrinkWrap: config.shrinkWrap ?? false,
      padding: config.padding,
      addAutomaticKeepAlives: config.addAutomaticKeepAlives ?? true,
      addRepaintBoundaries: config.addRepaintBoundaries ?? true,
      addSemanticIndexes: config.addSemanticIndexes ?? true,
      cacheExtent: config.cacheExtent,
      dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
      keyboardDismissBehavior:
          config.keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
      restorationId: config.restorationId,
      clipBehavior: config.clipBehavior ?? Clip.hardEdge,
      hitTestBehavior: config.hitTestBehavior ?? HitTestBehavior.opaque,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) {
        return KeyedSubtree(
          key: ValueKey('separator_$index'),
          child: config.separator!,
        );
      },
    );
  }
  return ListView.builder(
    scrollDirection: config.scrollDirection ?? Axis.vertical,
    reverse: config.reverse ?? false,
    controller: config.controller,
    primary: config.primary,
    physics: config.physics,
    shrinkWrap: config.shrinkWrap ?? false,
    padding: config.padding,
    itemExtent: config.itemExtent,
    itemExtentBuilder: config.itemExtentBuilder,
    prototypeItem: config.prototypeItem,
    addAutomaticKeepAlives: config.addAutomaticKeepAlives ?? true,
    addRepaintBoundaries: config.addRepaintBoundaries ?? true,
    addSemanticIndexes: config.addSemanticIndexes ?? true,
    cacheExtent: config.cacheExtent,
    semanticChildCount: semanticChildCount,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    keyboardDismissBehavior:
        config.keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
    restorationId: config.restorationId,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    hitTestBehavior: config.hitTestBehavior ?? HitTestBehavior.opaque,
    itemCount: children.length,
    itemBuilder: (context, index) => children[index],
  );
}

List<Object?> _resolveItems(Object? value) {
  if (value is Iterable) {
    return value.toList();
  }
  if (value == null) {
    return const [];
  }
  return [value];
}
