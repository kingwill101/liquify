import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ScaffoldTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ScaffoldTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      final resolvedBody = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'body',
        parser: (value) => value is Widget ? value : null,
      );
      final resolvedAppBar = resolvePropertyValue<PreferredSizeWidget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'appBar',
        parser: (value) => value is PreferredSizeWidget ? value : null,
      );
      buffer.write(
        Scaffold(
          appBar: resolvedAppBar ?? config.appBar,
          body: resolvedBody ?? config.body ?? wrapChildren(children),
          backgroundColor: config.backgroundColor,
          drawer: config.drawer,
          endDrawer: config.endDrawer,
          bottomNavigationBar: config.bottomNavigationBar,
          floatingActionButton: config.floatingActionButton,
          resizeToAvoidBottomInset: config.resizeToAvoidBottomInset,
          extendBody: config.extendBody ?? false,
          extendBodyBehindAppBar: config.extendBodyBehindAppBar ?? false,
        ),
      );
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
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      final resolvedBody = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'body',
        parser: (value) => value is Widget ? value : null,
      );
      final resolvedAppBar = resolvePropertyValue<PreferredSizeWidget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'appBar',
        parser: (value) => value is PreferredSizeWidget ? value : null,
      );
      buffer.write(
        Scaffold(
          appBar: resolvedAppBar ?? config.appBar,
          body: resolvedBody ?? config.body ?? wrapChildren(children),
          backgroundColor: config.backgroundColor,
          drawer: config.drawer,
          endDrawer: config.endDrawer,
          bottomNavigationBar: config.bottomNavigationBar,
          floatingActionButton: config.floatingActionButton,
          resizeToAvoidBottomInset: config.resizeToAvoidBottomInset,
          extendBody: config.extendBody ?? false,
          extendBodyBehindAppBar: config.extendBodyBehindAppBar ?? false,
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('scaffold').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endscaffold').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'scaffold',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ScaffoldConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _ScaffoldConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'appBar':
          if (value is PreferredSizeWidget) {
            config.appBar = value;
          }
          namedValues[name] = value;
          break;
        case 'body':
          if (value is Widget) {
            config.body = value;
          }
          namedValues[name] = value;
          break;
        case 'backgroundColor':
        case 'background':
          config.backgroundColor = parseColor(value);
          break;
        case 'drawer':
          if (value is Widget) {
            config.drawer = value;
          }
          break;
        case 'endDrawer':
          if (value is Widget) {
            config.endDrawer = value;
          }
          break;
        case 'bottomNavigationBar':
          if (value is Widget) {
            config.bottomNavigationBar = value;
          }
          break;
        case 'floatingActionButton':
          if (value is Widget) {
            config.floatingActionButton = value;
          }
          break;
        case 'resizeToAvoidBottomInset':
          config.resizeToAvoidBottomInset = toBool(value);
          break;
        case 'extendBody':
          config.extendBody = toBool(value);
          break;
        case 'extendBodyBehindAppBar':
          config.extendBodyBehindAppBar = toBool(value);
          break;
        default:
          handleUnknownArg('scaffold', name);
          break;
      }
    }
    return config;
  }
}

class _ScaffoldConfig {
  PreferredSizeWidget? appBar;
  Widget? body;
  Color? backgroundColor;
  Widget? drawer;
  Widget? endDrawer;
  Widget? bottomNavigationBar;
  Widget? floatingActionButton;
  bool? resizeToAvoidBottomInset;
  bool? extendBody;
  bool? extendBodyBehindAppBar;
}
