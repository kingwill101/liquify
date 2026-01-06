import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class OpacityTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  OpacityTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final opacity = _parseOpacity(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildOpacity(opacity, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final opacity = _parseOpacity(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildOpacity(opacity, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('opacity').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endopacity').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'opacity',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  double _parseOpacity(Evaluator evaluator) {
    double? value;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'value':
        case 'opacity':
          value = toDouble(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('opacity', name);
          break;
      }
    }
    value ??= toDouble(_evaluatePositionalValue(evaluator, content));
    if (value == null) {
      throw Exception('opacity tag requires an opacity value');
    }
    final clamped = switch (value) {
      < 0 => 0.0,
      > 1 => 1.0,
      _ => value,
    };
    return clamped;
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

Widget _buildOpacity(double opacity, List<Widget> children) {
  final child = wrapChildren(children);
  return Opacity(opacity: opacity, child: child);
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}

Object? _evaluatePositionalValue(Evaluator evaluator, List<ASTNode> content) {
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
