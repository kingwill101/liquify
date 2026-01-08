import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class PositionedTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  PositionedTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      config.width = resolvePropertyValue<double?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'width',
        parser: toDouble,
      );
      config.height = resolvePropertyValue<double?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'height',
        parser: toDouble,
      );
      buffer.write(_buildPositioned(config, children));
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
      final children = _asWidgets(captured);
      config.width = resolvePropertyValue<double?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'width',
        parser: toDouble,
      );
      config.height = resolvePropertyValue<double?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'height',
        parser: toDouble,
      );
      buffer.write(_buildPositioned(config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('positioned').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endpositioned').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'positioned',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _PositionedConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _PositionedConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'left':
          config.left = toDouble(value);
          break;
        case 'right':
          config.right = toDouble(value);
          break;
        case 'top':
          config.top = toDouble(value);
          break;
        case 'bottom':
          config.bottom = toDouble(value);
          break;
        case 'width':
          namedValues[name] = value;
          break;
        case 'height':
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('positioned', name);
          break;
      }
    }
    return config;
  }
}

class _PositionedConfig {
  double? left;
  double? right;
  double? top;
  double? bottom;
  double? width;
  double? height;
}

Widget _buildPositioned(_PositionedConfig config, List<Widget> children) {
  final child = wrapChildren(children);
  return Positioned(
    left: config.left,
    right: config.right,
    top: config.top,
    bottom: config.bottom,
    width: config.width,
    height: config.height,
    child: child,
  );
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
