// ignore_for_file: deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class IgnorePointerTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  IgnorePointerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildIgnorePointer(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(Evaluator evaluator, Buffer buffer) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildIgnorePointer(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('ignore_pointer').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endignore_pointer').trim() & tagEnd();
    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'ignore_pointer',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _IgnorePointerConfig _parseConfig(Evaluator evaluator) {
    final config = _IgnorePointerConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'ignoring':
          config.ignoring = toBool(value);
          break;
        case 'ignoringSemantics':
          config.ignoringSemantics = toBool(value);
          break;
        default:
          handleUnknownArg('ignore_pointer', name);
          break;
      }
    }
    return config;
  }
}

class _IgnorePointerConfig {
  bool? ignoring;
  bool? ignoringSemantics;
}

Widget _buildIgnorePointer(_IgnorePointerConfig config, List<Widget> children) {
  final child = children.isNotEmpty
      ? wrapChildren(children)
      : const SizedBox.shrink();
  return IgnorePointer(
    ignoring: config.ignoring ?? true,
    ignoringSemantics: config.ignoringSemantics,
    child: child,
  );
}
