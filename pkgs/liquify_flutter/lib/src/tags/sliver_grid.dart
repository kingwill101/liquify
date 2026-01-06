import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliverGridTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SliverGridTag(super.content, super.filters);

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
        string('sliver_grid').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsliver_grid').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'sliver_grid',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SliverGridConfig _parseConfig(Evaluator evaluator) {
    final config = _SliverGridConfig();
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
        case 'columns':
        case 'crossAxisCount':
          config.crossAxisCount = toInt(value);
          break;
        case 'maxCrossAxisExtent':
          config.maxCrossAxisExtent = toDouble(value);
          break;
        case 'mainAxisSpacing':
          config.mainAxisSpacing = toDouble(value);
          break;
        case 'crossAxisSpacing':
          config.crossAxisSpacing = toDouble(value);
          break;
        case 'childAspectRatio':
          config.childAspectRatio = toDouble(value);
          break;
        case 'mainAxisExtent':
          config.mainAxisExtent = toDouble(value);
          break;
        case 'gridDelegate':
          if (value is SliverGridDelegate) {
            config.gridDelegate = value;
          }
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
          handleUnknownArg('sliver_grid', name);
          break;
      }
    }
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    if (config.gap != null) {
      config.mainAxisSpacing ??= config.gap;
      config.crossAxisSpacing ??= config.gap;
    }
    return config;
  }

  Widget _buildSliver(Evaluator evaluator, _SliverGridConfig config) {
    final children = _buildChildren(evaluator, config);
    return _wrapSliver(config, children);
  }

  Future<Widget> _buildSliverAsync(
    Evaluator evaluator,
    _SliverGridConfig config,
  ) async {
    final children = await _buildChildrenAsync(evaluator, config);
    return _wrapSliver(config, children);
  }

  List<Widget> _buildChildren(Evaluator evaluator, _SliverGridConfig config) {
    final items = _resolveItems(config.items);
    if (items.isEmpty) {
      return captureChildrenSync(evaluator);
    }
    return _buildItems(evaluator, config, items, body);
  }

  Future<List<Widget>> _buildChildrenAsync(
    Evaluator evaluator,
    _SliverGridConfig config,
  ) async {
    final items = _resolveItems(config.items);
    if (items.isEmpty) {
      return captureChildrenAsync(evaluator);
    }
    return _buildItemsAsync(evaluator, config, items, body);
  }
}

class _SliverGridConfig {
  Object? items;
  String? itemName;
  String? indexName;
  int? crossAxisCount;
  double? maxCrossAxisExtent;
  double? mainAxisSpacing;
  double? crossAxisSpacing;
  double? childAspectRatio;
  double? mainAxisExtent;
  SliverGridDelegate? gridDelegate;
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
  _SliverGridConfig config,
  List<Object?> items,
  List<ASTNode> body,
) {
  final itemName = config.itemName?.trim().isNotEmpty == true
      ? config.itemName!
      : 'item';
  final indexName = config.indexName?.trim().isNotEmpty == true
      ? config.indexName!
      : 'index';
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
      widgets.add(widget);
    } finally {
      evaluator.context.popScope();
      popPropertyScope(evaluator.context, scope);
    }
  }
  return widgets;
}

Future<List<Widget>> _buildItemsAsync(
  Evaluator evaluator,
  _SliverGridConfig config,
  List<Object?> items,
  List<ASTNode> body,
) async {
  final itemName = config.itemName?.trim().isNotEmpty == true
      ? config.itemName!
      : 'item';
  final indexName = config.indexName?.trim().isNotEmpty == true
      ? config.indexName!
      : 'index';
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
      widgets.add(widget);
    } finally {
      evaluator.context.popScope();
      popPropertyScope(evaluator.context, scope);
    }
  }
  return widgets;
}

Widget _wrapSliver(_SliverGridConfig config, List<Widget> children) {
  final delegate = SliverChildListDelegate(
    children,
    addAutomaticKeepAlives: config.addAutomaticKeepAlives ?? true,
    addRepaintBoundaries: config.addRepaintBoundaries ?? true,
    addSemanticIndexes: config.addSemanticIndexes ?? true,
  );
  final gridDelegate =
      config.gridDelegate ??
      _resolveGridDelegate(
        crossAxisCount: config.crossAxisCount,
        maxCrossAxisExtent: config.maxCrossAxisExtent,
        mainAxisSpacing: config.mainAxisSpacing,
        crossAxisSpacing: config.crossAxisSpacing,
        childAspectRatio: config.childAspectRatio,
        mainAxisExtent: config.mainAxisExtent,
      );
  final sliver = SliverGrid(delegate: delegate, gridDelegate: gridDelegate);
  return config.padding == null
      ? sliver
      : SliverPadding(padding: config.padding!, sliver: sliver);
}

SliverGridDelegate _resolveGridDelegate({
  int? crossAxisCount,
  double? maxCrossAxisExtent,
  double? mainAxisSpacing,
  double? crossAxisSpacing,
  double? childAspectRatio,
  double? mainAxisExtent,
}) {
  if (crossAxisCount != null) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing ?? 0,
      crossAxisSpacing: crossAxisSpacing ?? 0,
      childAspectRatio: childAspectRatio ?? 1,
      mainAxisExtent: mainAxisExtent,
    );
  }
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxCrossAxisExtent ?? 120,
    mainAxisSpacing: mainAxisSpacing ?? 0,
    crossAxisSpacing: crossAxisSpacing ?? 0,
    childAspectRatio: childAspectRatio ?? 1,
    mainAxisExtent: mainAxisExtent,
  );
}
