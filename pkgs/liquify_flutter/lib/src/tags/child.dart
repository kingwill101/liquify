import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'widget_tag_base.dart';

class ChildTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ChildTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final children = _captureChildrenSync(evaluator);
    setPropertyValue(evaluator.context, 'child', _wrapChildren(children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final children = await _captureChildrenAsync(evaluator);
    setPropertyValue(evaluator.context, 'child', _wrapChildren(children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('child').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endchild').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'child',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
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

Widget _wrapChildren(List<Widget> children) {
  if (children.isEmpty) {
    return const SizedBox.shrink();
  }
  if (children.length == 1) {
    return children.first;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
