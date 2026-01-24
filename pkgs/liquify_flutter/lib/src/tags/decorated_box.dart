import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DecoratedBoxTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  DecoratedBoxTag(this.position, this.tagName, super.content, super.filters);

  final DecorationPosition position;
  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildBox(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildBox(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string(tagName).trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('end$tagName').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        tagName,
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _DecoratedBoxConfig _parseConfig(Evaluator evaluator) {
    final config = _DecoratedBoxConfig(position: position, tagName: tagName);
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'decoration':
          config.decoration = parseDecoration(evaluator, value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }
    return config;
  }

  Widget _buildBox(_DecoratedBoxConfig config, List<Widget> children) {
    final child = config.child ??
        (children.isEmpty
            ? const SizedBox.shrink()
            : children.length == 1
                ? children.first
                : wrapChildren(children));

    final decoration = config.decoration ?? const BoxDecoration();

    return DecoratedBox(
      decoration: decoration,
      position: config.position,
      child: child,
    );
  }
}

class _DecoratedBoxConfig {
  _DecoratedBoxConfig({required this.position, required this.tagName});

  final DecorationPosition position;
  final String tagName;
  Decoration? decoration;
  Widget? child;
}
