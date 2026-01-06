import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ExpandedTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ExpandedTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final flex = _parseFlex(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildExpanded(flex, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final flex = _parseFlex(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildExpanded(flex, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('expanded').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endexpanded').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'expanded',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  int _parseFlex(Evaluator evaluator) {
    var flex = 1;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'flex':
          flex = toInt(evaluator.evaluate(arg.value)) ?? 1;
          break;
        default:
          handleUnknownArg('expanded', name);
          break;
      }
    }
    return flex;
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

Widget _buildExpanded(int flex, List<Widget> children) {
  final child = wrapChildren(children);
  return Expanded(flex: flex, child: child);
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
