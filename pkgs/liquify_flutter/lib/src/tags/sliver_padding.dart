import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliverPaddingTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SliverPaddingTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final slivers = _wrapSlivers(WidgetTagBase.asWidgets(captured));
      buffer.write(_buildSliverPadding(evaluator.context, config, slivers));
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
      final slivers = _wrapSlivers(WidgetTagBase.asWidgets(captured));
      buffer.write(_buildSliverPadding(evaluator.context, config, slivers));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('sliver_padding').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsliver_padding').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'sliver_padding',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SliverPaddingConfig _parseConfig(Evaluator evaluator) {
    final config = _SliverPaddingConfig();
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'padding':
          namedValues[name] = value;
          break;
        case 'sliver':
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('sliver_padding', name);
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
}

class _SliverPaddingConfig {
  EdgeInsetsGeometry? padding;
  final Map<String, Object?> namedValues = {};
}

Widget _buildSliverPadding(
  Environment environment,
  _SliverPaddingConfig config,
  List<Widget> slivers,
) {
  if (config.padding == null) {
    throw Exception('sliver_padding tag requires "padding"');
  }
  final sliverOverride = resolvePropertyValue<Widget?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'sliver',
    parser: (value) => value is Widget ? value : null,
  );
  final childOverride = resolvePropertyValue<Widget?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );

  Widget sliver;
  if (sliverOverride != null) {
    sliver = sliverOverride;
  } else if (childOverride != null) {
    sliver = childOverride is SliverPadding
        ? childOverride
        : SliverToBoxAdapter(child: childOverride);
  } else if (slivers.isEmpty) {
    sliver = const SliverToBoxAdapter(child: SizedBox.shrink());
  } else if (slivers.length == 1) {
    sliver = slivers.first;
  } else {
    sliver = SliverList(
      delegate: SliverChildListDelegate(slivers),
    );
  }

  return SliverPadding(
    padding: config.padding!,
    sliver: sliver,
  );
}

List<Widget> _wrapSlivers(List<Widget> children) {
  if (children.isEmpty) {
    return const <Widget>[];
  }
  return children
      .map((child) => _isSliver(child)
          ? child
          : SliverToBoxAdapter(child: child))
      .toList();
}

bool _isSliver(Widget widget) {
  final name = widget.runtimeType.toString();
  return name.startsWith('Sliver');
}
