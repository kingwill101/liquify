import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'widget_tag_base.dart';

class ListSeparatorTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ListSeparatorTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    _validateArgs();
    final separator = _captureSeparatorSync(evaluator);
    setPropertyValue(evaluator.context, 'separator', separator);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    _validateArgs();
    final separator = await _captureSeparatorAsync(evaluator);
    setPropertyValue(evaluator.context, 'separator', separator);
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('list_separator').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endlist_separator').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'list_separator',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  Widget _captureSeparatorSync(Evaluator evaluator) {
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
    return Column(children: children);
  }

  Future<Widget> _captureSeparatorAsync(Evaluator evaluator) async {
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
    return Column(children: children);
  }

  void _validateArgs() {
    for (final arg in namedArgs) {
      handleUnknownArg('list_separator', arg.identifier.name);
    }
  }
}
