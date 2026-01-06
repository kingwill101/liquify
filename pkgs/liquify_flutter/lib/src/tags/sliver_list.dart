import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliverListTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SliverListTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final sliver = _buildSliver(evaluator, config);
    buffer.write(sliver);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final sliver = await _buildSliverAsync(evaluator, config);
    buffer.write(sliver);
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('sliver_list').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsliver_list').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'sliver_list',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SliverListConfig _parseConfig(Evaluator evaluator) {
    final config = _SliverListConfig();
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'items':
          config.items = value;
          break;
        case 'itemName':
          config.itemName = value?.toString();
          break;
        case 'indexName':
          config.indexName = value?.toString();
          break;
        case 'gap':
          config.gap = toDouble(value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'addAutomaticKeepAlives':
          config.addAutomaticKeepAlives = toBool(value);
          break;
        case 'addRepaintBoundaries':
          config.addRepaintBoundaries = toBool(value);
          break;
        case 'addSemanticIndexes':
          config.addSemanticIndexes = toBool(value);
          break;
        default:
          handleUnknownArg('sliver_list', name);
          break;
      }
    }
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    return config;
  }

  Widget _buildSliver(Evaluator evaluator, _SliverListConfig config) {
    final children = _buildChildren(evaluator, config);
    final delegate = SliverChildListDelegate(
      children,
      addAutomaticKeepAlives: config.addAutomaticKeepAlives ?? true,
      addRepaintBoundaries: config.addRepaintBoundaries ?? true,
      addSemanticIndexes: config.addSemanticIndexes ?? true,
    );
    final sliver = SliverList(delegate: delegate);
    return config.padding == null
        ? sliver
        : SliverPadding(padding: config.padding!, sliver: sliver);
  }

  Future<Widget> _buildSliverAsync(
    Evaluator evaluator,
    _SliverListConfig config,
  ) async {
    final children = await _buildChildrenAsync(evaluator, config);
    final delegate = SliverChildListDelegate(
      children,
      addAutomaticKeepAlives: config.addAutomaticKeepAlives ?? true,
      addRepaintBoundaries: config.addRepaintBoundaries ?? true,
      addSemanticIndexes: config.addSemanticIndexes ?? true,
    );
    final sliver = SliverList(delegate: delegate);
    return config.padding == null
        ? sliver
        : SliverPadding(padding: config.padding!, sliver: sliver);
  }

  List<Widget> _buildChildren(Evaluator evaluator, _SliverListConfig config) {
    final items = _resolveItems(config.items);
    if (items.isEmpty) {
      return captureChildrenSync(evaluator);
    }
    return _buildItems(evaluator, config, items, body);
  }

  Future<List<Widget>> _buildChildrenAsync(
    Evaluator evaluator,
    _SliverListConfig config,
  ) async {
    final items = _resolveItems(config.items);
    if (items.isEmpty) {
      return captureChildrenAsync(evaluator);
    }
    return _buildItemsAsync(evaluator, config, items, body);
  }
}

class _SliverListConfig {
  Object? items;
  String? itemName;
  String? indexName;
  double? gap;
  EdgeInsetsGeometry? padding;
  bool? addAutomaticKeepAlives;
  bool? addRepaintBoundaries;
  bool? addSemanticIndexes;
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

List<Widget> _buildItems(
  Evaluator evaluator,
  _SliverListConfig config,
  List<Object?> items,
  List<ASTNode> body,
) {
  final itemName = config.itemName?.trim().isNotEmpty == true
      ? config.itemName!
      : 'item';
  final indexName = config.indexName?.trim().isNotEmpty == true
      ? config.indexName!
      : 'index';
  final padding = config.gap == null || config.gap == 0
      ? null
      : EdgeInsets.only(bottom: config.gap!);
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
        padding == null ? widget : Padding(padding: padding, child: widget),
      );
    } finally {
      evaluator.context.popScope();
      popPropertyScope(evaluator.context, scope);
    }
  }
  return widgets;
}

Future<List<Widget>> _buildItemsAsync(
  Evaluator evaluator,
  _SliverListConfig config,
  List<Object?> items,
  List<ASTNode> body,
) async {
  final itemName = config.itemName?.trim().isNotEmpty == true
      ? config.itemName!
      : 'item';
  final indexName = config.indexName?.trim().isNotEmpty == true
      ? config.indexName!
      : 'index';
  final padding = config.gap == null || config.gap == 0
      ? null
      : EdgeInsets.only(bottom: config.gap!);
  final widgets = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    final scope = pushPropertyScope(evaluator.context);
    evaluator.context.pushScope();
    evaluator.context.setVariable(itemName, items[i]);
    evaluator.context.setVariable(indexName, i);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      if (children.isEmpty) {
        continue;
      }
      final widget = children.length == 1
          ? children.first
          : wrapChildren(children);
      widgets.add(
        padding == null ? widget : Padding(padding: padding, child: widget),
      );
    } finally {
      evaluator.context.popScope();
      popPropertyScope(evaluator.context, scope);
    }
  }
  return widgets;
}
