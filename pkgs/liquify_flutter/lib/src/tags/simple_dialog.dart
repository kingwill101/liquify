import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SimpleDialogTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  SimpleDialogTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildDialog(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildDialog(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('simple_dialog').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endsimple_dialog').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'simple_dialog',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _SimpleDialogConfig _parseConfig(Evaluator evaluator) {
    final config = _SimpleDialogConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'title':
          config.title = _resolveTextOrWidget(value);
          break;
        case 'backgroundColor':
          config.backgroundColor = parseColor(value);
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'titlePadding':
          config.titlePadding = parseEdgeInsetsGeometry(value);
          break;
        case 'contentPadding':
          config.contentPadding = parseEdgeInsetsGeometry(value);
          break;
        default:
          handleUnknownArg('simple_dialog', name);
          break;
      }
    }
    return config;
  }
}

class _SimpleDialogConfig {
  Widget? title;
  Color? backgroundColor;
  double? elevation;
  ShapeBorder? shape;
  Clip? clipBehavior;
  EdgeInsetsGeometry? titlePadding;
  EdgeInsetsGeometry? contentPadding;
}

Widget _buildDialog(_SimpleDialogConfig config, List<Widget> children) {
  return SimpleDialog(
    title: config.title,
    backgroundColor: config.backgroundColor,
    elevation: config.elevation,
    shape: config.shape,
    clipBehavior: config.clipBehavior,
    titlePadding:
        config.titlePadding ?? const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
    contentPadding:
        config.contentPadding ??
        const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
    children: children.isEmpty ? null : children,
  );
}

Widget? _resolveTextOrWidget(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Widget) {
    return value;
  }
  return Text(value.toString());
}
