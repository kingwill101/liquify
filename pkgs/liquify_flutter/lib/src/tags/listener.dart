import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

typedef PointerSignalEventListener = void Function(PointerSignalEvent);

class ListenerTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ListenerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildListener(evaluator, namedValues, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildListener(evaluator, namedValues, config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('listener').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endlistener').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'listener',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ListenerConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _ListenerConfig();
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? childValue;
    Object? onPointerDownValue;
    Object? onPointerMoveValue;
    Object? onPointerUpValue;
    Object? onPointerCancelValue;
    Object? onPointerSignalValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        case 'behavior':
        case 'hitTestBehavior':
          config.behavior = parseHitTestBehavior(value);
          break;
        case 'onPointerDown':
          onPointerDownValue = value;
          break;
        case 'onPointerMove':
          onPointerMoveValue = value;
          break;
        case 'onPointerUp':
          onPointerUpValue = value;
          break;
        case 'onPointerCancel':
          onPointerCancelValue = value;
          break;
        case 'onPointerSignal':
          onPointerSignalValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('listener', name);
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
      'listener',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;

    config.onPointerDown = _wrapPointerDownCallback(
      evaluator,
      onPointerDownValue,
      ids,
      'pointer_down',
    );
    config.onPointerMove = _wrapPointerMoveCallback(
      evaluator,
      onPointerMoveValue,
      ids,
      'pointer_move',
    );
    config.onPointerUp = _wrapPointerUpCallback(
      evaluator,
      onPointerUpValue,
      ids,
      'pointer_up',
    );
    config.onPointerCancel = _wrapPointerCancelCallback(
      evaluator,
      onPointerCancelValue,
      ids,
      'pointer_cancel',
    );
    config.onPointerSignal = _wrapPointerSignalCallback(
      evaluator,
      onPointerSignalValue,
      ids,
      'pointer_signal',
    );

    return config;
  }
}

class _ListenerConfig {
  Widget? child;
  HitTestBehavior? behavior;
  Key? widgetKey;
  PointerDownEventListener? onPointerDown;
  PointerMoveEventListener? onPointerMove;
  PointerUpEventListener? onPointerUp;
  PointerCancelEventListener? onPointerCancel;
  PointerSignalEventListener? onPointerSignal;
}

Widget _buildListener(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _ListenerConfig config,
  List<Widget> children,
) {
  final resolvedChild = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );
  final child = resolvedChild ?? config.child ?? wrapChildren(children);

  return Listener(
    key: config.widgetKey,
    behavior: config.behavior ?? HitTestBehavior.deferToChild,
    onPointerDown: config.onPointerDown,
    onPointerMove: config.onPointerMove,
    onPointerUp: config.onPointerUp,
    onPointerCancel: config.onPointerCancel,
    onPointerSignal: config.onPointerSignal,
    child: child,
  );
}

PointerDownEventListener? _wrapPointerDownCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'listener',
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

PointerMoveEventListener? _wrapPointerMoveCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'listener',
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

PointerUpEventListener? _wrapPointerUpCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'listener',
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

PointerCancelEventListener? _wrapPointerCancelCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'listener',
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

PointerSignalEventListener? _wrapPointerSignalCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'listener',
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
