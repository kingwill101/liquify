import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

typedef PointerEnterEventListener = void Function(PointerEnterEvent);
typedef PointerExitEventListener = void Function(PointerExitEvent);
typedef PointerHoverEventListener = void Function(PointerHoverEvent);

class MouseRegionTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  MouseRegionTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildMouseRegion(evaluator, namedValues, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildMouseRegion(evaluator, namedValues, config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('mouse_region').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endmouse_region').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'mouse_region',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _MouseRegionConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _MouseRegionConfig();
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? childValue;
    Object? onEnterValue;
    Object? onExitValue;
    Object? onHoverValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        case 'cursor':
        case 'mouseCursor':
          config.cursor = parseMouseCursor(value);
          break;
        case 'opaque':
          config.opaque = toBool(value);
          break;
        case 'onEnter':
          onEnterValue = value;
          break;
        case 'onExit':
          onExitValue = value;
          break;
        case 'onHover':
          onHoverValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('mouse_region', name);
          break;
      }
    }

    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      config.child = resolvedChild;
    } else if (childValue != null) {
      config.child = childValue is Widget
          ? childValue
          : resolveTextWidget(childValue);
    }

    final ids = resolveIds(
      evaluator,
      'mouse_region',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;

    config.onEnter = _wrapMouseEnterCallback(
      evaluator,
      onEnterValue,
      ids,
      'enter',
    );
    config.onExit = _wrapMouseExitCallback(evaluator, onExitValue, ids, 'exit');
    config.onHover = _wrapMouseHoverCallback(
      evaluator,
      onHoverValue,
      ids,
      'hover',
    );

    return config;
  }
}

class _MouseRegionConfig {
  Widget? child;
  Key? widgetKey;
  MouseCursor? cursor;
  bool? opaque;
  PointerEnterEventListener? onEnter;
  PointerExitEventListener? onExit;
  PointerHoverEventListener? onHover;
}

Widget _buildMouseRegion(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _MouseRegionConfig config,
  List<Widget> children,
) {
  final resolvedChild = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );
  final child = resolvedChild ?? config.child ?? wrapChildren(children);

  return MouseRegion(
    key: config.widgetKey,
    cursor: config.cursor ?? MouseCursor.defer,
    opaque: config.opaque ?? true,
    onEnter: config.onEnter,
    onExit: config.onExit,
    onHover: config.onHover,
    child: child,
  );
}

PointerEnterEventListener? _wrapMouseEnterCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'mouse_region',
      id: ids.id,
      key: ids.keyValue,
      event: eventName,
    ),
    actionValue: value is String ? value : null,
  );
  if (action == null) {
    return null;
  }
  return (_) => action();
}

PointerExitEventListener? _wrapMouseExitCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'mouse_region',
      id: ids.id,
      key: ids.keyValue,
      event: eventName,
    ),
    actionValue: value is String ? value : null,
  );
  if (action == null) {
    return null;
  }
  return (_) => action();
}

PointerHoverEventListener? _wrapMouseHoverCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'mouse_region',
      id: ids.id,
      key: ids.keyValue,
      event: eventName,
    ),
    actionValue: value is String ? value : null,
  );
  if (action == null) {
    return null;
  }
  return (_) => action();
}
