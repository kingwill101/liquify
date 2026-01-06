import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class BottomSheetTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  BottomSheetTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildBottomSheet(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildBottomSheet(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('bottom_sheet').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endbottom_sheet').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'bottom_sheet',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _BottomSheetConfig _parseConfig(Evaluator evaluator) {
    final config = _BottomSheetConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'constraints':
          config.constraints = parseBoxConstraints(value);
          break;
        case 'enableDrag':
          config.enableDrag = toBool(value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          break;
        default:
          handleUnknownArg('bottom_sheet', name);
          break;
      }
    }
    return config;
  }
}

class _BottomSheetConfig {
  Color? backgroundColor;
  double? elevation;
  ShapeBorder? shape;
  Clip? clipBehavior;
  BoxConstraints? constraints;
  bool? enableDrag;
  Widget? child;
}

Widget _buildBottomSheet(_BottomSheetConfig config, List<Widget> children) {
  final child = config.child ??
      (children.isEmpty ? const SizedBox.shrink() : wrapChildren(children));
  return BottomSheet(
    onClosing: () {},
    backgroundColor: config.backgroundColor,
    elevation: config.elevation,
    shape: config.shape,
    clipBehavior: config.clipBehavior ?? Clip.none,
    constraints: config.constraints,
    enableDrag: config.enableDrag ?? true,
    builder: (_) => child,
  );
}
