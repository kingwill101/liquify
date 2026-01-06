import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SliverPersistentHeaderTag extends WidgetTagBase
    with CustomTagParser, AsyncTag {
  SliverPersistentHeaderTag(super.content, super.filters);

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
    final start = tagStart() &
        string('sliver_persistent_header').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() &
        string('endsliver_persistent_header').trim() &
        tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'sliver_persistent_header',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SliverPersistentHeaderConfig _parseConfig(Evaluator evaluator) {
    final config = _SliverPersistentHeaderConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'minExtent':
          config.minExtent = toDouble(value);
          break;
        case 'maxExtent':
          config.maxExtent = toDouble(value);
          break;
        case 'pinned':
          config.pinned = toBool(value);
          break;
        case 'floating':
          config.floating = toBool(value);
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('sliver_persistent_header', name);
          break;
      }
    }
    return config;
  }
}

class _SliverPersistentHeaderConfig {
  double? minExtent;
  double? maxExtent;
  bool? pinned;
  bool? floating;
  final Map<String, Object?> namedValues = {};
}

Widget _buildSliver(
  Environment environment,
  _SliverPersistentHeaderConfig config,
  List<Widget> children,
) {
  if (config.minExtent == null || config.maxExtent == null) {
    throw Exception('sliver_persistent_header requires minExtent and maxExtent');
  }

  final childOverride = resolvePropertyValue<Widget?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );

  final child = childOverride ??
      (children.isEmpty
          ? const SizedBox.shrink()
          : children.length == 1
              ? children.first
              : wrapChildren(children));

  return SliverPersistentHeader(
    pinned: config.pinned ?? false,
    floating: config.floating ?? false,
    delegate: _SimplePersistentHeaderDelegate(
      minExtentValue: config.minExtent!,
      maxExtentValue: config.maxExtent!,
      child: child,
    ),
  );
}

class _SimplePersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SimplePersistentHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SimplePersistentHeaderDelegate oldDelegate) {
    return minExtentValue != oldDelegate.minExtentValue ||
        maxExtentValue != oldDelegate.maxExtentValue ||
        child != oldDelegate.child;
  }
}
