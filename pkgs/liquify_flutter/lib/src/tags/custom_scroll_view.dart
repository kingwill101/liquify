import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class CustomScrollViewTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  CustomScrollViewTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final slivers = _captureSliversSync(evaluator);
    buffer.write(_buildScrollView(config, slivers));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final slivers = await _captureSliversAsync(evaluator);
    buffer.write(_buildScrollView(config, slivers));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('custom_scroll_view').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endcustom_scroll_view').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'custom_scroll_view',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _CustomScrollConfig _parseConfig(Evaluator evaluator) {
    final config = _CustomScrollConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'direction':
        case 'axis':
        case 'scrollDirection':
          config.scrollDirection = parseAxis(value);
          break;
        case 'reverse':
          config.reverse = toBool(value);
          break;
        case 'controller':
          if (value is ScrollController) {
            config.controller = value;
          }
          break;
        case 'primary':
          config.primary = toBool(value);
          break;
        case 'physics':
          config.physics = parseScrollPhysics(value);
          break;
        case 'shrinkWrap':
          config.shrinkWrap = toBool(value);
          break;
        case 'anchor':
          config.anchor = toDouble(value);
          break;
        case 'cacheExtent':
          config.cacheExtent = toDouble(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'restorationId':
          config.restorationId = value?.toString();
          break;
        case 'keyboardDismissBehavior':
          config.keyboardDismissBehavior =
              parseScrollViewKeyboardDismissBehavior(value);
          break;
        default:
          handleUnknownArg('custom_scroll_view', name);
          break;
      }
    }
    return config;
  }

  List<Widget> _captureSliversSync(Evaluator evaluator) {
    final children = captureChildrenSync(evaluator);
    return _wrapSlivers(children);
  }

  Future<List<Widget>> _captureSliversAsync(Evaluator evaluator) async {
    final children = await captureChildrenAsync(evaluator);
    return _wrapSlivers(children);
  }
}

class _CustomScrollConfig {
  Axis? scrollDirection;
  bool? reverse;
  ScrollController? controller;
  bool? primary;
  ScrollPhysics? physics;
  bool? shrinkWrap;
  double? anchor;
  double? cacheExtent;
  DragStartBehavior? dragStartBehavior;
  Clip? clipBehavior;
  String? restorationId;
  ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
}

CustomScrollView _buildScrollView(
  _CustomScrollConfig config,
  List<Widget> slivers,
) {
  return CustomScrollView(
    scrollDirection: config.scrollDirection ?? Axis.vertical,
    reverse: config.reverse ?? false,
    controller: config.controller,
    primary: config.primary,
    physics: config.physics,
    shrinkWrap: config.shrinkWrap ?? false,
    anchor: config.anchor ?? 0.0,
    cacheExtent: config.cacheExtent,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    restorationId: config.restorationId,
    keyboardDismissBehavior: config.keyboardDismissBehavior,
    slivers: slivers,
  );
}

List<Widget> _wrapSlivers(List<Widget> children) {
  if (children.isEmpty) {
    return const <Widget>[];
  }
  return children
      .map(
        (child) => _isSliver(child) ? child : SliverToBoxAdapter(child: child),
      )
      .toList();
}

bool _isSliver(Widget widget) {
  final name = widget.runtimeType.toString();
  return name.startsWith('Sliver');
}
