import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class RowTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  RowTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    double? spacing;
    MainAxisAlignment? mainAxisAlignment;
    MainAxisSize? mainAxisSize;
    CrossAxisAlignment? crossAxisAlignment;
    TextDirection? textDirection;
    VerticalDirection? verticalDirection;
    TextBaseline? textBaseline;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'gap':
          spacing ??= toDouble(evaluator.evaluate(arg.value));
          break;
        case 'spacing':
          spacing = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'mainAxisAlignment':
          mainAxisAlignment = parseMainAxisAlignment(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'mainAxisSize':
          mainAxisSize = parseMainAxisSize(evaluator.evaluate(arg.value));
          break;
        case 'crossAxisAlignment':
          crossAxisAlignment = parseCrossAxisAlignment(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'textDirection':
          textDirection = parseTextDirection(evaluator.evaluate(arg.value));
          break;
        case 'verticalDirection':
          verticalDirection = parseVerticalDirection(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'textBaseline':
          textBaseline = parseTextBaseline(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('row', name);
          break;
      }
    }
    final children = _captureChildrenSync(evaluator);
    buffer.write(
      Row(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        mainAxisSize: mainAxisSize ?? MainAxisSize.max,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
        textDirection: textDirection,
        verticalDirection: verticalDirection ?? VerticalDirection.down,
        textBaseline: textBaseline,
        spacing: spacing ?? 0,
        children: children,
      ),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    double? spacing;
    MainAxisAlignment? mainAxisAlignment;
    MainAxisSize? mainAxisSize;
    CrossAxisAlignment? crossAxisAlignment;
    TextDirection? textDirection;
    VerticalDirection? verticalDirection;
    TextBaseline? textBaseline;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'gap':
          spacing ??= toDouble(evaluator.evaluate(arg.value));
          break;
        case 'spacing':
          spacing = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'mainAxisAlignment':
          mainAxisAlignment = parseMainAxisAlignment(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'mainAxisSize':
          mainAxisSize = parseMainAxisSize(evaluator.evaluate(arg.value));
          break;
        case 'crossAxisAlignment':
          crossAxisAlignment = parseCrossAxisAlignment(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'textDirection':
          textDirection = parseTextDirection(evaluator.evaluate(arg.value));
          break;
        case 'verticalDirection':
          verticalDirection = parseVerticalDirection(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'textBaseline':
          textBaseline = parseTextBaseline(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('row', name);
          break;
      }
    }
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(
      Row(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        mainAxisSize: mainAxisSize ?? MainAxisSize.max,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
        textDirection: textDirection,
        verticalDirection: verticalDirection ?? VerticalDirection.down,
        textBaseline: textBaseline,
        spacing: spacing ?? 0,
        children: children,
      ),
    );
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('row').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endrow').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'row',
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

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
