import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ScrollViewTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ScrollViewTag(this.tagName, super.content, super.filters);

  final String tagName;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      final padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      buffer.write(
        _buildScrollView(config, children, paddingOverride: padding),
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
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      final padding = resolvePropertyValue<EdgeInsetsGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'padding',
        parser: parseEdgeInsetsGeometry,
      );
      buffer.write(
        _buildScrollView(config, children, paddingOverride: padding),
      );
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string(tagName).trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('end$tagName').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        tagName,
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ScrollConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    Axis axis = Axis.vertical;
    bool reverse = false;
    bool? primary;
    EdgeInsetsGeometry? padding;
    ScrollPhysics? physics;
    ScrollController? controller;
    DragStartBehavior? dragStartBehavior;
    Clip clipBehavior = Clip.hardEdge;
    HitTestBehavior? hitTestBehavior;
    String? restorationId;
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'direction':
        case 'axis':
        case 'scrollDirection':
          axis = parseAxis(evaluator.evaluate(arg.value)) ?? axis;
          break;
        case 'reverse':
          reverse = toBool(evaluator.evaluate(arg.value)) ?? false;
          break;
        case 'primary':
          primary = toBool(evaluator.evaluate(arg.value));
          break;
        case 'padding':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'physics':
          physics = parseScrollPhysics(evaluator.evaluate(arg.value));
          break;
        case 'controller':
          final value = evaluator.evaluate(arg.value);
          if (value is ScrollController) {
            controller = value;
          }
          break;
        case 'dragStartBehavior':
          dragStartBehavior = parseDragStartBehavior(
            evaluator.evaluate(arg.value),
          );
          break;
        case 'clip':
        case 'clipBehavior':
          clipBehavior =
              parseClip(evaluator.evaluate(arg.value)) ?? clipBehavior;
          break;
        case 'hitTestBehavior':
          hitTestBehavior = parseHitTestBehavior(evaluator.evaluate(arg.value));
          break;
        case 'restorationId':
          restorationId = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'keyboardDismissBehavior':
          keyboardDismissBehavior = parseScrollViewKeyboardDismissBehavior(
            evaluator.evaluate(arg.value),
          );
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }

    return _ScrollConfig(
      axis: axis,
      reverse: reverse,
      primary: primary,
      padding: padding,
      physics: physics,
      controller: controller,
      dragStartBehavior: dragStartBehavior,
      clipBehavior: clipBehavior,
      hitTestBehavior: hitTestBehavior,
      restorationId: restorationId,
      keyboardDismissBehavior: keyboardDismissBehavior,
    );
  }

  Widget _buildScrollView(
    _ScrollConfig config,
    List<Widget> children, {
    EdgeInsetsGeometry? paddingOverride,
  }) {
    final padding = paddingOverride ?? config.padding;
    return SingleChildScrollView(
      scrollDirection: config.axis,
      reverse: config.reverse,
      padding: padding,
      primary: config.primary,
      physics: config.physics,
      controller: config.controller,
      dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
      clipBehavior: config.clipBehavior,
      hitTestBehavior: config.hitTestBehavior ?? HitTestBehavior.opaque,
      restorationId: config.restorationId,
      keyboardDismissBehavior: config.keyboardDismissBehavior,
      child: wrapChildren(children),
    );
  }
}

class _ScrollConfig {
  _ScrollConfig({
    required this.axis,
    required this.reverse,
    required this.primary,
    required this.padding,
    required this.physics,
    required this.controller,
    required this.dragStartBehavior,
    required this.clipBehavior,
    required this.hitTestBehavior,
    required this.restorationId,
    required this.keyboardDismissBehavior,
  });

  final Axis axis;
  final bool reverse;
  final bool? primary;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final DragStartBehavior? dragStartBehavior;
  final Clip clipBehavior;
  final HitTestBehavior? hitTestBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
