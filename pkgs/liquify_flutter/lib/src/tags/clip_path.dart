import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ClipPathTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ClipPathTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildClipPath(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildClipPath(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('clip_path').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endclip_path').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'clip_path',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ClipPathConfig _parseConfig(Evaluator evaluator) {
    final config = _ClipPathConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'clipper':
          if (value is CustomClipper<Path>) {
            config.clipper = value;
          }
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          break;
        default:
          handleUnknownArg('clip_path', name);
          break;
      }
    }
    return config;
  }
}

class _ClipPathConfig {
  CustomClipper<Path>? clipper;
  ShapeBorder? shape;
  Clip? clipBehavior;
  Widget? child;
}

Widget _buildClipPath(_ClipPathConfig config, List<Widget> children) {
  final child = config.child ??
      (children.isEmpty
          ? const SizedBox.shrink()
          : children.length == 1
              ? children.first
              : wrapChildren(children));

  final clipper = config.clipper ??
      (config.shape == null
          ? null
          : ShapeBorderClipper(shape: config.shape!));

  return ClipPath(
    clipper: clipper,
    clipBehavior: config.clipBehavior ?? Clip.antiAlias,
    child: child,
  );
}
