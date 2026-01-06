import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class PageViewTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  PageViewTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildPageView(evaluator, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildPageView(evaluator, config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('page_view').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endpage_view').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'page_view',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _PageViewConfig _parseConfig(Evaluator evaluator) {
    final config = _PageViewConfig();
    Object? onPageChangedValue;
    Object? childrenValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'children':
          childrenValue = value;
          break;
        case 'scrollDirection':
          config.scrollDirection = parseAxis(value);
          break;
        case 'reverse':
          config.reverse = toBool(value);
          break;
        case 'controller':
          if (value is PageController) {
            config.controller = value;
          }
          break;
        case 'physics':
          config.physics = parseScrollPhysics(value);
          break;
        case 'pageSnapping':
          config.pageSnapping = toBool(value);
          break;
        case 'onPageChanged':
          onPageChangedValue = value;
          break;
        case 'allowImplicitScrolling':
          config.allowImplicitScrolling = toBool(value);
          break;
        case 'padEnds':
          config.padEnds = toBool(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        default:
          handleUnknownArg('page_view', name);
          break;
      }
    }

    config.children = _resolveChildren(childrenValue);

    final actionName = onPageChangedValue is String ? onPageChangedValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'page_view',
      id: 'page_view',
      key: 'page_view',
      action: actionName,
      event: 'page_changed',
    );
    config.onPageChanged = resolveIntActionCallback(
      evaluator,
      onPageChangedValue,
      event: baseEvent,
      actionValue: actionName,
    );

    return config;
  }
}

class _PageViewConfig {
  Axis? scrollDirection;
  bool? reverse;
  PageController? controller;
  ScrollPhysics? physics;
  bool? pageSnapping;
  ValueChanged<int>? onPageChanged;
  bool? allowImplicitScrolling;
  bool? padEnds;
  DragStartBehavior? dragStartBehavior;
  Clip? clipBehavior;
  List<Widget>? children;
}

Widget _buildPageView(
  Evaluator evaluator,
  _PageViewConfig config,
  List<Widget> capturedChildren,
) {
  final children =
      config.children ??
      (capturedChildren.isEmpty ? const <Widget>[] : capturedChildren);
  if (children.isEmpty) {
    return const SizedBox.shrink();
  }

  return PageView(
    scrollDirection: config.scrollDirection ?? Axis.horizontal,
    reverse: config.reverse ?? false,
    controller: config.controller,
    physics: config.physics,
    pageSnapping: config.pageSnapping ?? true,
    onPageChanged: config.onPageChanged,
    allowImplicitScrolling: config.allowImplicitScrolling ?? false,
    padEnds: config.padEnds ?? true,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    children: children,
  );
}

List<Widget>? _resolveChildren(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Widget) {
    return [value];
  }
  if (value is Iterable) {
    return value.expand(WidgetTagBase.asWidgets).toList();
  }
  return WidgetTagBase.asWidgets(value);
}
