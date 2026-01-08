import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SafeAreaTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SafeAreaTag(super.content, super.filters);

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
      final resolvedChild = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'child',
        parser: (value) => value is Widget ? value : null,
      );
      buffer.write(
        SafeArea(
          left: config.left ?? true,
          top: config.top ?? true,
          right: config.right ?? true,
          bottom: config.bottom ?? true,
          minimum: config.minimum ?? EdgeInsets.zero,
          maintainBottomViewPadding:
              config.maintainBottomViewPadding ?? false,
          child: resolvedChild ?? wrapChildren(children),
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
      final resolvedChild = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'child',
        parser: (value) => value is Widget ? value : null,
      );
      buffer.write(
        SafeArea(
          left: config.left ?? true,
          top: config.top ?? true,
          right: config.right ?? true,
          bottom: config.bottom ?? true,
          minimum: config.minimum ?? EdgeInsets.zero,
          maintainBottomViewPadding:
              config.maintainBottomViewPadding ?? false,
          child: resolvedChild ?? wrapChildren(children),
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('safe_area').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsafe_area').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'safe_area',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SafeAreaConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _SafeAreaConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'left':
          config.left = toBool(value);
          break;
        case 'top':
          config.top = toBool(value);
          break;
        case 'right':
          config.right = toBool(value);
          break;
        case 'bottom':
          config.bottom = toBool(value);
          break;
        case 'minimum':
          final resolved = parseEdgeInsetsGeometry(value);
          if (resolved is EdgeInsets) {
            config.minimum = resolved;
          }
          break;
        case 'maintainBottomViewPadding':
          config.maintainBottomViewPadding = toBool(value);
          break;
        case 'child':
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('safe_area', name);
          break;
      }
    }
    return config;
  }
}

class _SafeAreaConfig {
  bool? left;
  bool? top;
  bool? right;
  bool? bottom;
  EdgeInsets? minimum;
  bool? maintainBottomViewPadding;
}
