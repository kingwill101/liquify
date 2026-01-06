import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliverFillRemainingTag extends WidgetTagBase
    with CustomTagParser, AsyncTag {
  SliverFillRemainingTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildSliver(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildSliver(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('sliver_fill_remaining').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endsliver_fill_remaining').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'sliver_fill_remaining',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SliverFillRemainingConfig _parseConfig(Evaluator evaluator) {
    final config = _SliverFillRemainingConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'hasScrollBody':
          config.hasScrollBody = toBool(value);
          break;
        case 'fillOverscroll':
          config.fillOverscroll = toBool(value);
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('sliver_fill_remaining', name);
          break;
      }
    }
    return config;
  }
}

class _SliverFillRemainingConfig {
  bool? hasScrollBody;
  bool? fillOverscroll;
  final Map<String, Object?> namedValues = {};
}

Widget _buildSliver(
  Environment environment,
  _SliverFillRemainingConfig config,
  List<Widget> children,
) {
  final childOverride = resolvePropertyValue<Widget?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );

  final child =
      childOverride ??
      (children.isEmpty
          ? const SizedBox.shrink()
          : children.length == 1
          ? children.first
          : wrapChildren(children));

  return SliverFillRemaining(
    hasScrollBody: config.hasScrollBody ?? true,
    fillOverscroll: config.fillOverscroll ?? false,
    child: child,
  );
}
