import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class LayoutBuilderTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  LayoutBuilderTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final child = _captureChildSync(evaluator);
    buffer.write(_buildLayoutBuilder(child));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final child = await _captureChildAsync(evaluator);
    buffer.write(_buildLayoutBuilder(child));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('layout_builder').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endlayout_builder').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'layout_builder',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  Widget _captureChildSync(Evaluator evaluator) {
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    final captured = evaluator.popBufferValue();
    final children = WidgetTagBase.asWidgets(captured);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.first;
    }
    return wrapChildren(children);
  }

  Future<Widget> _captureChildAsync(Evaluator evaluator) async {
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    final captured = evaluator.popBufferValue();
    final children = WidgetTagBase.asWidgets(captured);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.first;
    }
    return wrapChildren(children);
  }
}

Widget _buildLayoutBuilder(Widget child) {
  return LayoutBuilder(builder: (context, constraints) => child);
}
