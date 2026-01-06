import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ReorderableListTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ReorderableListTag(this.tagName, super.content, super.filters);

  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final items = _resolveItems(config.items);
    final built = _buildItems(evaluator, config, items);
    buffer.write(_buildList(config, built));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final items = _resolveItems(config.items);
    final built = _buildItems(evaluator, config, items);
    buffer.write(_buildList(config, built));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string(tagName).trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('end$tagName').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        tagName,
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ReorderableListConfig _parseConfig(Evaluator evaluator) {
    final config = _ReorderableListConfig();
    final namedValues = <String, Object?>{};
    Object? actionValue;
    Object? onReorderValue;
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
        case 'itemKey':
          config.itemKey = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
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
        case 'scrollController':
          final value = evaluator.evaluate(arg.value);
          if (value is ScrollController) {
            config.scrollController = value;
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
        case 'itemExtent':
          config.itemExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'prototypeItem':
          final value = evaluator.evaluate(arg.value);
          if (value is Widget) {
            config.prototypeItem = value;
          }
          break;
        case 'header':
          config.header = resolveTextWidget(evaluator.evaluate(arg.value));
          break;
        case 'footer':
          config.footer = resolveTextWidget(evaluator.evaluate(arg.value));
          break;
        case 'cacheExtent':
          config.cacheExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(
            evaluator.evaluate(arg.value),
          );
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
        case 'buildDefaultDragHandles':
          config.buildDefaultDragHandles = toBool(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'action':
          actionValue = evaluator.evaluate(arg.value);
          break;
        case 'onReorder':
          onReorderValue = evaluator.evaluate(arg.value);
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }

    final resolvedPadding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    config.padding = resolvedPadding?.resolve(TextDirection.ltr);

    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'reorderable_list',
      id: 'reorderable_list',
      key: 'reorderable_list',
      action: actionName,
      event: 'reorder',
    );
    config.onReorder =
        resolveReorderActionCallback(
          evaluator,
          onReorderValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveReorderActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    return config;
  }

  List<Widget> _buildItems(
    Evaluator evaluator,
    _ReorderableListConfig config,
    List<Object?> items,
  ) {
    if (items.isEmpty) {
      return const [];
    }
    final itemName = config.itemName?.trim().isNotEmpty == true
        ? config.itemName!
        : 'item';
    final indexName = config.indexName?.trim().isNotEmpty == true
        ? config.indexName!
        : 'index';
    final keyName = config.itemKey?.trim().isNotEmpty == true
        ? config.itemKey!
        : 'id';
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
        final widget = children.length == 1
            ? children.first
            : wrapChildren(children);
        widgets.add(
          KeyedSubtree(key: _resolveKey(items[i], keyName, i), child: widget),
        );
      } finally {
        evaluator.context.popScope();
        popPropertyScope(evaluator.context, scope);
      }
    }
    return widgets;
  }
}

class _ReorderableListConfig {
  Object? items;
  String? itemName;
  String? indexName;
  String? itemKey;
  EdgeInsets? padding;
  Axis? scrollDirection;
  bool? reverse;
  ScrollController? scrollController;
  bool? primary;
  ScrollPhysics? physics;
  bool? shrinkWrap;
  double? itemExtent;
  Widget? prototypeItem;
  Widget? header;
  Widget? footer;
  double? cacheExtent;
  DragStartBehavior? dragStartBehavior;
  ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  String? restorationId;
  Clip? clipBehavior;
  bool? buildDefaultDragHandles;
  ReorderActionCallback? onReorder;
}

ReorderableListView _buildList(
  _ReorderableListConfig config,
  List<Widget> children,
) {
  return ReorderableListView(
    scrollDirection: config.scrollDirection ?? Axis.vertical,
    reverse: config.reverse ?? false,
    scrollController: config.scrollController,
    primary: config.primary,
    physics: config.physics,
    shrinkWrap: config.shrinkWrap ?? false,
    padding: config.padding,
    itemExtent: config.itemExtent,
    prototypeItem: config.prototypeItem,
    header: config.header,
    footer: config.footer,
    cacheExtent: config.cacheExtent,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    keyboardDismissBehavior:
        config.keyboardDismissBehavior ??
        ScrollViewKeyboardDismissBehavior.manual,
    restorationId: config.restorationId,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    buildDefaultDragHandles: config.buildDefaultDragHandles ?? true,
    onReorder: config.onReorder ?? (oldIndex, newIndex) {},
    children: children,
  );
}

Key _resolveKey(Object? item, String keyName, int index) {
  if (item is Map && item.containsKey(keyName)) {
    final value = item[keyName];
    if (value != null) {
      return ValueKey(value);
    }
  }
  if (item != null && item is! Map) {
    return ValueKey(item);
  }
  return ValueKey(index);
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
