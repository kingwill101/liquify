import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ConstrainedBoxTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ConstrainedBoxTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildConstrainedBox(evaluator.context, config, children));
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
      buffer.write(_buildConstrainedBox(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('constrained_box').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endconstrained_box').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'constrained_box',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ConstrainedBoxConfig _parseConfig(Evaluator evaluator) {
    final config = _ConstrainedBoxConfig();
    final constraintValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'constraints':
          config.constraints = parseBoxConstraints(value);
          break;
        case 'minWidth':
        case 'maxWidth':
        case 'minHeight':
        case 'maxHeight':
          constraintValues[name] = value;
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('constrained_box', name);
          break;
      }
    }
    if (config.constraints == null && constraintValues.isNotEmpty) {
      config.constraints = parseBoxConstraints(constraintValues);
    }
    return config;
  }
}

class _ConstrainedBoxConfig {
  BoxConstraints? constraints;
  final Map<String, Object?> namedValues = {};
}

Widget _buildConstrainedBox(
  Environment environment,
  _ConstrainedBoxConfig config,
  List<Widget> children,
) {
  if (config.constraints == null) {
    throw Exception(
      'constrained_box tag requires "constraints" or min/max values',
    );
  }
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

  return ConstrainedBox(constraints: config.constraints!, child: child);
}
