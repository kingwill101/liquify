import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FractionallySizedBoxTag extends WidgetTagBase
    with CustomTagParser, AsyncTag {
  FractionallySizedBoxTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(
        _buildFractionallySizedBox(evaluator.context, config, children),
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
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(
        _buildFractionallySizedBox(evaluator.context, config, children),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('fractionally_sized_box').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endfractionally_sized_box').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'fractionally_sized_box',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FractionallySizedBoxConfig _parseConfig(Evaluator evaluator) {
    final config = _FractionallySizedBoxConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'widthFactor':
          config.widthFactor = toDouble(value);
          break;
        case 'heightFactor':
          config.heightFactor = toDouble(value);
          break;
        case 'alignment':
          config.alignment = parseAlignmentGeometry(value);
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('fractionally_sized_box', name);
          break;
      }
    }
    return config;
  }
}

class _FractionallySizedBoxConfig {
  double? widthFactor;
  double? heightFactor;
  AlignmentGeometry? alignment;
  final Map<String, Object?> namedValues = {};
}

Widget _buildFractionallySizedBox(
  Environment environment,
  _FractionallySizedBoxConfig config,
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

  return FractionallySizedBox(
    widthFactor: config.widthFactor,
    heightFactor: config.heightFactor,
    alignment: config.alignment ?? Alignment.center,
    child: child,
  );
}
