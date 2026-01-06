import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class OverflowBoxTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  OverflowBoxTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildOverflowBox(evaluator.context, config, children));
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
      buffer.write(_buildOverflowBox(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('overflow_box').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endoverflow_box').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'overflow_box',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _OverflowBoxConfig _parseConfig(Evaluator evaluator) {
    final config = _OverflowBoxConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'alignment':
          config.alignment = parseAlignmentGeometry(value);
          break;
        case 'minWidth':
          config.minWidth = toDouble(value);
          break;
        case 'maxWidth':
          config.maxWidth = toDouble(value);
          break;
        case 'minHeight':
          config.minHeight = toDouble(value);
          break;
        case 'maxHeight':
          config.maxHeight = toDouble(value);
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('overflow_box', name);
          break;
      }
    }
    return config;
  }
}

class _OverflowBoxConfig {
  AlignmentGeometry? alignment;
  double? minWidth;
  double? maxWidth;
  double? minHeight;
  double? maxHeight;
  final Map<String, Object?> namedValues = {};
}

Widget _buildOverflowBox(
  Environment environment,
  _OverflowBoxConfig config,
  List<Widget> children,
) {
  final childOverride = resolvePropertyValue<Widget?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );

  Widget child;
  if (childOverride != null) {
    child = childOverride;
  } else if (children.isEmpty) {
    child = const SizedBox.shrink();
  } else if (children.length == 1) {
    child = children.first;
  } else {
    child = wrapChildren(children);
  }

  return OverflowBox(
    alignment: config.alignment ?? Alignment.center,
    minWidth: config.minWidth,
    maxWidth: config.maxWidth,
    minHeight: config.minHeight,
    maxHeight: config.maxHeight,
    child: child,
  );
}
