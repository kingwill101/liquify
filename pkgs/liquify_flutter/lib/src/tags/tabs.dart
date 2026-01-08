import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'tabs_props.dart';
import 'widget_tag_base.dart';

class TabsTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TabsTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    try {
      final entries = _captureEntriesSync(evaluator);
      config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      config.contentHeight = resolvePropertyValue<double?>(
            environment: evaluator.context,
            namedArgs: namedValues,
            name: 'height',
            parser: toDouble,
          ) ??
          config.contentHeight;
      buffer.write(_buildTabs(config, entries));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    try {
      final entries = await _captureEntriesAsync(evaluator);
      config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      config.contentHeight = resolvePropertyValue<double?>(
            environment: evaluator.context,
            namedArgs: namedValues,
            name: 'height',
            parser: toDouble,
          ) ??
          config.contentHeight;
      buffer.write(_buildTabs(config, entries));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('tabs').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endtabs').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'tabs',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _TabsConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _TabsConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'initial':
        case 'initialIndex':
          config.initialIndex = toInt(evaluator.evaluate(arg.value));
          break;
        case 'height':
          final value = evaluator.evaluate(arg.value);
          config.contentHeight = toDouble(value);
          namedValues[name] = value;
          break;
        case 'contentHeight':
          config.contentHeight = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'gap':
          config.gap = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'isScrollable':
          config.isScrollable = toBool(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'indicatorColor':
          config.indicatorColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'labelColor':
          config.labelColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'unselectedLabelColor':
          config.unselectedLabelColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'labelSize':
          config.labelSize = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'labelWeight':
          config.labelWeight = parseFontWeight(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('tabs', name);
          break;
      }
    }
    return config;
  }

  List<TabEntry> _captureEntriesSync(Evaluator evaluator) {
    final previous = getTabsSpec(evaluator.context);
    final spec = TabsSpec();
    setTabsSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      evaluator.popBufferValue();
      return spec.entries;
    } finally {
      setTabsSpec(evaluator.context, previous);
    }
  }

  Future<List<TabEntry>> _captureEntriesAsync(Evaluator evaluator) async {
    final previous = getTabsSpec(evaluator.context);
    final spec = TabsSpec();
    setTabsSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      evaluator.popBufferValue();
      return spec.entries;
    } finally {
      setTabsSpec(evaluator.context, previous);
    }
  }

  Widget _buildTabs(_TabsConfig config, List<TabEntry> entries) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final tabs = entries.map((entry) => entry.tab).toList();
    final views = entries.map((entry) => entry.view).toList();
    final labelStyle = (config.labelSize != null || config.labelWeight != null)
        ? TextStyle(
            fontSize: config.labelSize,
            fontWeight: config.labelWeight,
          )
        : null;

    Widget buildView(double? height, BoxConstraints constraints) {
      final view = TabBarView(children: views);
      if (height != null) {
        return SizedBox(height: height, child: view);
      }
      if (constraints.hasBoundedHeight) {
        return Expanded(child: view);
      }
      return SizedBox(height: 280, child: view);
    }

    return DefaultTabController(
      length: tabs.length,
      initialIndex: config.initialIndex ?? 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                isScrollable: config.isScrollable ?? false,
                padding: config.padding,
                indicatorColor: config.indicatorColor,
                labelColor: config.labelColor,
                unselectedLabelColor: config.unselectedLabelColor,
                labelStyle: labelStyle,
                tabs: tabs,
              ),
              if ((config.gap ?? 0) > 0)
                SizedBox(height: config.gap ?? 0),
              buildView(config.contentHeight, constraints),
            ],
          );
        },
      ),
    );
  }
}

class TabTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TabTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final entry = _buildEntry(evaluator, _captureChildrenSync(evaluator));
    final spec = getTabsSpec(evaluator.context);
    if (spec == null) {
      buffer.write(entry.tab);
      return;
    }
    spec.entries.add(entry);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final children = await _captureChildrenAsync(evaluator);
    final entry = _buildEntry(evaluator, children);
    final spec = getTabsSpec(evaluator.context);
    if (spec == null) {
      buffer.write(entry.tab);
      return;
    }
    spec.entries.add(entry);
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('tab').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endtab').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'tab',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  TabEntry _buildEntry(Evaluator evaluator, List<Widget> children) {
    String? label;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'label':
        case 'title':
          label = evaluator.evaluate(arg.value)?.toString();
          break;
        default:
          handleUnknownArg('tab', name);
          break;
      }
    }
    if (label == null || label.trim().isEmpty) {
      label = 'Tab';
    }
    final view = wrapChildren(children);
    return TabEntry(tab: Tab(text: label), view: view);
  }

  List<Widget> _captureChildrenSync(Evaluator evaluator) {
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      return _asWidgets(captured);
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  Future<List<Widget>> _captureChildrenAsync(Evaluator evaluator) async {
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      return _asWidgets(captured);
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }
}

class _TabsConfig {
  int? initialIndex;
  double? contentHeight;
  double? gap;
  bool? isScrollable;
  EdgeInsetsGeometry? padding;
  Color? indicatorColor;
  Color? labelColor;
  Color? unselectedLabelColor;
  double? labelSize;
  FontWeight? labelWeight;
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
