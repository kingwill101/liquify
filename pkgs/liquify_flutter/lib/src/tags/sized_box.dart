import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SizedBoxTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SizedBoxTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildSizedBox(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildSizedBox(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('sized_box').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsized_box').trim() & tagEnd();
    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'sized_box',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SizedBoxConfig _parseConfig(Evaluator evaluator) {
    final config = _SizedBoxConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'width':
          config.width = toDouble(value);
          break;
        case 'height':
          config.height = toDouble(value);
          break;
        default:
          handleUnknownArg('sized_box', name);
          break;
      }
    }
    return config;
  }
}

class _SizedBoxConfig {
  double? width;
  double? height;
}

Widget _buildSizedBox(_SizedBoxConfig config, List<Widget> children) {
  final child = children.isNotEmpty ? wrapChildren(children) : null;
  return SizedBox(width: config.width, height: config.height, child: child);
}
