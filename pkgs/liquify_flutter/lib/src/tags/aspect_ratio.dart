import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AspectRatioTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  AspectRatioTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final ratio = _parseRatio(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildAspect(ratio, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final ratio = _parseRatio(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildAspect(ratio, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('aspect_ratio').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endaspect_ratio').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'aspect_ratio',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  double _parseRatio(Evaluator evaluator) {
    double? ratio;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'value':
        case 'ratio':
          ratio = toDouble(value);
          break;
        default:
          handleUnknownArg('aspect_ratio', name);
          break;
      }
    }
    ratio ??= toDouble(_evaluatePositionalValue(evaluator, content));
    if (ratio == null || ratio <= 0) {
      throw Exception('aspect_ratio tag requires a positive ratio');
    }
    return ratio;
  }

  List<Widget> _captureChildrenSync(Evaluator evaluator) {
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    final captured = evaluator.popBufferValue();
    return _asWidgets(captured);
  }

  Future<List<Widget>> _captureChildrenAsync(Evaluator evaluator) async {
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    final captured = evaluator.popBufferValue();
    return _asWidgets(captured);
  }
}

Widget _buildAspect(double ratio, List<Widget> children) {
  final child = wrapChildren(children);
  return AspectRatio(aspectRatio: ratio, child: child);
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}

Object? _evaluatePositionalValue(
  Evaluator evaluator,
  List<ASTNode> content,
) {
  final positional = content.where((node) => node is! NamedArgument).toList();
  if (positional.isEmpty) {
    return null;
  }
  if (positional.length == 1) {
    return evaluator.evaluate(positional.first);
  }
  final buffer = StringBuffer();
  for (final node in positional) {
    buffer.write(evaluator.evaluate(node));
  }
  return buffer.toString();
}
