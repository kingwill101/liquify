import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ListTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ListTag(this.tagName, super.content, super.filters);

  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    double? gap;
    Axis? scrollDirection;
    bool? reverse;
    ScrollController? controller;
    bool? primary;
    ScrollPhysics? physics;
    bool? shrinkWrap;
    EdgeInsetsGeometry? padding;
    double? itemExtent;
    ItemExtentBuilder? itemExtentBuilder;
    Widget? prototypeItem;
    bool? addAutomaticKeepAlives;
    bool? addRepaintBoundaries;
    bool? addSemanticIndexes;
    double? cacheExtent;
    int? semanticChildCount;
    DragStartBehavior? dragStartBehavior;
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
    String? restorationId;
    Clip? clipBehavior;
    HitTestBehavior? hitTestBehavior;
    Widget? separator;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'gap':
          gap = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'scrollDirection':
        case 'direction':
        case 'axis':
          scrollDirection = parseAxis(evaluator.evaluate(arg.value));
          break;
        case 'reverse':
          reverse = toBool(evaluator.evaluate(arg.value));
          break;
        case 'controller':
          final value = evaluator.evaluate(arg.value);
          if (value is ScrollController) {
            controller = value;
          }
          break;
        case 'primary':
          primary = toBool(evaluator.evaluate(arg.value));
          break;
        case 'physics':
          physics = parseScrollPhysics(evaluator.evaluate(arg.value));
          break;
        case 'shrinkWrap':
          shrinkWrap = toBool(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'separator':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'itemExtent':
          itemExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'itemExtentBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ItemExtentBuilder) {
            itemExtentBuilder = value;
          }
          break;
        case 'prototypeItem':
          final value = evaluator.evaluate(arg.value);
          if (value is Widget) {
            prototypeItem = value;
          }
          break;
        case 'addAutomaticKeepAlives':
          addAutomaticKeepAlives = toBool(evaluator.evaluate(arg.value));
          break;
        case 'addRepaintBoundaries':
          addRepaintBoundaries = toBool(evaluator.evaluate(arg.value));
          break;
        case 'addSemanticIndexes':
          addSemanticIndexes = toBool(evaluator.evaluate(arg.value));
          break;
        case 'cacheExtent':
          cacheExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'semanticChildCount':
          semanticChildCount = toInt(evaluator.evaluate(arg.value));
          break;
        case 'dragStartBehavior':
          dragStartBehavior = parseDragStartBehavior(evaluator.evaluate(arg.value));
          break;
        case 'keyboardDismissBehavior':
          keyboardDismissBehavior =
              parseScrollViewKeyboardDismissBehavior(
                evaluator.evaluate(arg.value),
              );
          break;
        case 'restorationId':
          restorationId = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'hitTestBehavior':
          hitTestBehavior = parseHitTestBehavior(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      separator = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'separator',
        parser: (value) => value is Widget ? value : null,
      );
      final axisForGap = scrollDirection ?? Axis.vertical;
      final spaced = withSeparator(
        withGap(children, gap, axisForGap),
        separator,
      );
      buffer.write(
        ListView(
          scrollDirection: scrollDirection ?? Axis.vertical,
          reverse: reverse ?? false,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap ?? false,
          padding: padding,
          itemExtent: itemExtent,
          itemExtentBuilder: itemExtentBuilder,
          prototypeItem: prototypeItem,
          addAutomaticKeepAlives: addAutomaticKeepAlives ?? true,
          addRepaintBoundaries: addRepaintBoundaries ?? true,
          addSemanticIndexes: addSemanticIndexes ?? true,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior ?? DragStartBehavior.start,
          keyboardDismissBehavior:
              keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
          restorationId: restorationId,
          clipBehavior: clipBehavior ?? Clip.hardEdge,
          hitTestBehavior: hitTestBehavior ?? HitTestBehavior.opaque,
          children: spaced,
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
    double? gap;
    Axis? scrollDirection;
    bool? reverse;
    ScrollController? controller;
    bool? primary;
    ScrollPhysics? physics;
    bool? shrinkWrap;
    EdgeInsetsGeometry? padding;
    double? itemExtent;
    ItemExtentBuilder? itemExtentBuilder;
    Widget? prototypeItem;
    bool? addAutomaticKeepAlives;
    bool? addRepaintBoundaries;
    bool? addSemanticIndexes;
    double? cacheExtent;
    int? semanticChildCount;
    DragStartBehavior? dragStartBehavior;
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
    String? restorationId;
    Clip? clipBehavior;
    HitTestBehavior? hitTestBehavior;
    Widget? separator;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'gap':
          gap = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'scrollDirection':
        case 'direction':
        case 'axis':
          scrollDirection = parseAxis(evaluator.evaluate(arg.value));
          break;
        case 'reverse':
          reverse = toBool(evaluator.evaluate(arg.value));
          break;
        case 'controller':
          final value = evaluator.evaluate(arg.value);
          if (value is ScrollController) {
            controller = value;
          }
          break;
        case 'primary':
          primary = toBool(evaluator.evaluate(arg.value));
          break;
        case 'physics':
          physics = parseScrollPhysics(evaluator.evaluate(arg.value));
          break;
        case 'shrinkWrap':
          shrinkWrap = toBool(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'separator':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'itemExtent':
          itemExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'itemExtentBuilder':
          final value = evaluator.evaluate(arg.value);
          if (value is ItemExtentBuilder) {
            itemExtentBuilder = value;
          }
          break;
        case 'prototypeItem':
          final value = evaluator.evaluate(arg.value);
          if (value is Widget) {
            prototypeItem = value;
          }
          break;
        case 'addAutomaticKeepAlives':
          addAutomaticKeepAlives = toBool(evaluator.evaluate(arg.value));
          break;
        case 'addRepaintBoundaries':
          addRepaintBoundaries = toBool(evaluator.evaluate(arg.value));
          break;
        case 'addSemanticIndexes':
          addSemanticIndexes = toBool(evaluator.evaluate(arg.value));
          break;
        case 'cacheExtent':
          cacheExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'semanticChildCount':
          semanticChildCount = toInt(evaluator.evaluate(arg.value));
          break;
        case 'dragStartBehavior':
          dragStartBehavior = parseDragStartBehavior(evaluator.evaluate(arg.value));
          break;
        case 'keyboardDismissBehavior':
          keyboardDismissBehavior =
              parseScrollViewKeyboardDismissBehavior(
                evaluator.evaluate(arg.value),
              );
          break;
        case 'restorationId':
          restorationId = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior = parseClip(evaluator.evaluate(arg.value));
          break;
        case 'hitTestBehavior':
          hitTestBehavior = parseHitTestBehavior(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      separator = resolvePropertyValue<Widget?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'separator',
        parser: (value) => value is Widget ? value : null,
      );
      final axisForGap = scrollDirection ?? Axis.vertical;
      final spaced = withSeparator(
        withGap(children, gap, axisForGap),
        separator,
      );
      buffer.write(
        ListView(
          scrollDirection: scrollDirection ?? Axis.vertical,
          reverse: reverse ?? false,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap ?? false,
          padding: padding,
          itemExtent: itemExtent,
          itemExtentBuilder: itemExtentBuilder,
          prototypeItem: prototypeItem,
          addAutomaticKeepAlives: addAutomaticKeepAlives ?? true,
          addRepaintBoundaries: addRepaintBoundaries ?? true,
          addSemanticIndexes: addSemanticIndexes ?? true,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior ?? DragStartBehavior.start,
          keyboardDismissBehavior:
              keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
          restorationId: restorationId,
          clipBehavior: clipBehavior ?? Clip.hardEdge,
          hitTestBehavior: hitTestBehavior ?? HitTestBehavior.opaque,
          children: spaced,
        ),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string(tagName).trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('end$tagName').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        tagName,
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
