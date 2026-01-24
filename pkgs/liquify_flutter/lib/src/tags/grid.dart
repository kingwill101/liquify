import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class GridTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  GridTag(this.tagName, super.content, super.filters);

  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    int? columns;
    double? maxCrossAxisExtent;
    double? gap;
    double? mainAxisSpacing;
    double? crossAxisSpacing;
    double? childAspectRatio;
    double? mainAxisExtent;
    Axis? scrollDirection;
    bool? reverse;
    ScrollController? controller;
    bool? primary;
    ScrollPhysics? physics;
    bool? shrinkWrap;
    EdgeInsetsGeometry? padding;
    SliverGridDelegate? gridDelegate;
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
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'columns':
          columns = toInt(evaluator.evaluate(arg.value));
          break;
        case 'maxCrossAxisExtent':
          maxCrossAxisExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'gap':
          gap = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'mainAxisSpacing':
          mainAxisSpacing = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'crossAxisSpacing':
          crossAxisSpacing = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'childAspectRatio':
          childAspectRatio = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'mainAxisExtent':
          mainAxisExtent = toDouble(evaluator.evaluate(arg.value));
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
        case 'gridDelegate':
          final value = evaluator.evaluate(arg.value);
          if (value is SliverGridDelegate) {
            gridDelegate = value;
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
    mainAxisSpacing ??= gap;
    crossAxisSpacing ??= gap;
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
      buffer.write(
        GridView(
          scrollDirection: scrollDirection ?? Axis.vertical,
          reverse: reverse ?? false,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap ?? false,
          padding: padding,
          gridDelegate: gridDelegate ??
              _resolveGridDelegate(
                tagName,
                columns,
                maxCrossAxisExtent,
                mainAxisSpacing,
                crossAxisSpacing,
                childAspectRatio,
                mainAxisExtent,
              ),
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
    int? columns;
    double? maxCrossAxisExtent;
    double? gap;
    double? mainAxisSpacing;
    double? crossAxisSpacing;
    double? childAspectRatio;
    double? mainAxisExtent;
    Axis? scrollDirection;
    bool? reverse;
    ScrollController? controller;
    bool? primary;
    ScrollPhysics? physics;
    bool? shrinkWrap;
    EdgeInsetsGeometry? padding;
    SliverGridDelegate? gridDelegate;
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
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'columns':
          columns = toInt(evaluator.evaluate(arg.value));
          break;
        case 'maxCrossAxisExtent':
          maxCrossAxisExtent = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'gap':
          gap = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'mainAxisSpacing':
          mainAxisSpacing = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'crossAxisSpacing':
          crossAxisSpacing = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'childAspectRatio':
          childAspectRatio = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'mainAxisExtent':
          mainAxisExtent = toDouble(evaluator.evaluate(arg.value));
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
        case 'gridDelegate':
          final value = evaluator.evaluate(arg.value);
          if (value is SliverGridDelegate) {
            gridDelegate = value;
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
    mainAxisSpacing ??= gap;
    crossAxisSpacing ??= gap;
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
      buffer.write(
        GridView(
          scrollDirection: scrollDirection ?? Axis.vertical,
          reverse: reverse ?? false,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap ?? false,
          padding: padding,
          gridDelegate: gridDelegate ??
              _resolveGridDelegate(
                tagName,
                columns,
                maxCrossAxisExtent,
                mainAxisSpacing,
                crossAxisSpacing,
                childAspectRatio,
                mainAxisExtent,
              ),
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

SliverGridDelegate _resolveGridDelegate(
  String tagName,
  int? columns,
  double? maxCrossAxisExtent,
  double? mainAxisSpacing,
  double? crossAxisSpacing,
  double? childAspectRatio,
  double? mainAxisExtent,
) {
  if (columns != null) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: mainAxisSpacing ?? 0,
      crossAxisSpacing: crossAxisSpacing ?? 0,
      childAspectRatio: childAspectRatio ?? 1.0,
      mainAxisExtent: mainAxisExtent,
    );
  }
  if (maxCrossAxisExtent != null) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      mainAxisSpacing: mainAxisSpacing ?? 0,
      crossAxisSpacing: crossAxisSpacing ?? 0,
      childAspectRatio: childAspectRatio ?? 1.0,
      mainAxisExtent: mainAxisExtent,
    );
  }
  throw Exception('$tagName tag requires "columns" or "maxCrossAxisExtent"');
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
