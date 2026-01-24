import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class StackTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  StackTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    StackFit? fit;
    TextDirection? textDirection;
    Clip? clipBehavior;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'alignment':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'fit':
          fit = parseStackFit(evaluator.evaluate(arg.value));
          break;
        case 'textDirection':
          textDirection = parseTextDirection(evaluator.evaluate(arg.value));
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('stack', name);
          break;
      }
    }
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      final alignment = resolvePropertyValue<AlignmentGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'alignment',
        parser: parseAlignmentGeometry,
      );
      buffer.write(
        Stack(
          alignment: alignment ?? AlignmentDirectional.topStart,
          textDirection: textDirection,
          fit: fit ?? StackFit.loose,
          clipBehavior: clipBehavior ?? Clip.hardEdge,
          children: children,
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    StackFit? fit;
    TextDirection? textDirection;
    Clip? clipBehavior;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'alignment':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'fit':
          fit = parseStackFit(evaluator.evaluate(arg.value));
          break;
        case 'textDirection':
          textDirection = parseTextDirection(evaluator.evaluate(arg.value));
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('stack', name);
          break;
      }
    }
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      final alignment = resolvePropertyValue<AlignmentGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'alignment',
        parser: parseAlignmentGeometry,
      );
      buffer.write(
        Stack(
          alignment: alignment ?? AlignmentDirectional.topStart,
          textDirection: textDirection,
          fit: fit ?? StackFit.loose,
          clipBehavior: clipBehavior ?? Clip.hardEdge,
          children: children,
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('stack').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endstack').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'stack',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
