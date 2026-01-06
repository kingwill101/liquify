import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ColoredBoxTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ColoredBoxTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildColoredBox(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildColoredBox(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('colored_box').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endcolored_box').trim() & tagEnd();
    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'colored_box',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ColoredBoxConfig _parseConfig(Evaluator evaluator) {
    final config = _ColoredBoxConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'color':
          config.color = parseColor(value);
          break;
        default:
          handleUnknownArg('colored_box', name);
          break;
      }
    }
    if (config.color == null) {
      throw Exception('colored_box tag requires "color"');
    }
    return config;
  }
}

class _ColoredBoxConfig {
  Color? color;
}

Widget _buildColoredBox(_ColoredBoxConfig config, List<Widget> children) {
  final child = children.isNotEmpty
      ? wrapChildren(children)
      : const SizedBox.shrink();
  return ColoredBox(color: config.color!, child: child);
}
