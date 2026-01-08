import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class GestureDetectorTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  GestureDetectorTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildGestureDetector(evaluator, namedValues, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildGestureDetector(evaluator, namedValues, config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('gesture_detector').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endgesture_detector').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'gesture_detector',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _GestureDetectorConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _GestureDetectorConfig();
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? childValue;
    Object? onTapValue;
    Object? onDoubleTapValue;
    Object? onLongPressValue;
    Object? onTapDownValue;
    Object? onTapUpValue;
    Object? onTapCancelValue;
    Object? onPanStartValue;
    Object? onPanUpdateValue;
    Object? onPanEndValue;
    Object? onPanCancelValue;

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
        case 'excludeFromSemantics':
          config.excludeFromSemantics = toBool(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        case 'onTap':
          onTapValue = value;
          break;
        case 'onDoubleTap':
          onDoubleTapValue = value;
          break;
        case 'onLongPress':
          onLongPressValue = value;
          break;
        case 'onTapDown':
          onTapDownValue = value;
          break;
        case 'onTapUp':
          onTapUpValue = value;
          break;
        case 'onTapCancel':
          onTapCancelValue = value;
          break;
        case 'onPanStart':
          onPanStartValue = value;
          break;
        case 'onPanUpdate':
          onPanUpdateValue = value;
          break;
        case 'onPanEnd':
          onPanEndValue = value;
          break;
        case 'onPanCancel':
          onPanCancelValue = value;
          break;
        default:
          handleUnknownArg('gesture_detector', name);
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
      config.child =
          childValue is Widget ? childValue : resolveTextWidget(childValue);
    }

    final ids = resolveIds(
      evaluator,
      'gesture_detector',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;

    config.onTap = resolveActionCallback(
      evaluator,
      onTapValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'tap',
      ),
      actionValue: onTapValue is String ? onTapValue : null,
    );
    config.onDoubleTap = resolveActionCallback(
      evaluator,
      onDoubleTapValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'double_tap',
      ),
      actionValue: onDoubleTapValue is String ? onDoubleTapValue : null,
    );
    config.onLongPress = resolveActionCallback(
      evaluator,
      onLongPressValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'long_press',
      ),
      actionValue: onLongPressValue is String ? onLongPressValue : null,
    );

    final tapDown = resolveActionCallback(
      evaluator,
      onTapDownValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'tap_down',
      ),
      actionValue: onTapDownValue is String ? onTapDownValue : null,
    );
    if (tapDown != null) {
      config.onTapDown = (_) => tapDown();
    }

    final tapUp = resolveActionCallback(
      evaluator,
      onTapUpValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'tap_up',
      ),
      actionValue: onTapUpValue is String ? onTapUpValue : null,
    );
    if (tapUp != null) {
      config.onTapUp = (_) => tapUp();
    }

    config.onTapCancel = resolveActionCallback(
      evaluator,
      onTapCancelValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'tap_cancel',
      ),
      actionValue: onTapCancelValue is String ? onTapCancelValue : null,
    );

    final panStart = resolveActionCallback(
      evaluator,
      onPanStartValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'pan_start',
      ),
      actionValue: onPanStartValue is String ? onPanStartValue : null,
    );
    if (panStart != null) {
      config.onPanStart = (_) => panStart();
    }

    final panUpdate = resolveActionCallback(
      evaluator,
      onPanUpdateValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'pan_update',
      ),
      actionValue: onPanUpdateValue is String ? onPanUpdateValue : null,
    );
    if (panUpdate != null) {
      config.onPanUpdate = (_) => panUpdate();
    }

    final panEnd = resolveActionCallback(
      evaluator,
      onPanEndValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'pan_end',
      ),
      actionValue: onPanEndValue is String ? onPanEndValue : null,
    );
    if (panEnd != null) {
      config.onPanEnd = (_) => panEnd();
    }

    config.onPanCancel = resolveActionCallback(
      evaluator,
      onPanCancelValue,
      event: buildWidgetEvent(
        tag: 'gesture_detector',
        id: ids.id,
        key: ids.keyValue,
        event: 'pan_cancel',
      ),
      actionValue: onPanCancelValue is String ? onPanCancelValue : null,
    );

    return config;
  }
}

class _GestureDetectorConfig {
  Widget? child;
  Key? widgetKey;
  HitTestBehavior? behavior;
  bool? excludeFromSemantics;
  DragStartBehavior? dragStartBehavior;
  VoidCallback? onTap;
  VoidCallback? onDoubleTap;
  VoidCallback? onLongPress;
  GestureTapDownCallback? onTapDown;
  GestureTapUpCallback? onTapUp;
  VoidCallback? onTapCancel;
  GestureDragStartCallback? onPanStart;
  GestureDragUpdateCallback? onPanUpdate;
  GestureDragEndCallback? onPanEnd;
  VoidCallback? onPanCancel;
}

Widget _buildGestureDetector(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _GestureDetectorConfig config,
  List<Widget> children,
) {
  final resolvedChild = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );
  final child = resolvedChild ?? config.child ?? wrapChildren(children);

  return GestureDetector(
    key: config.widgetKey,
    behavior: config.behavior,
    excludeFromSemantics: config.excludeFromSemantics ?? false,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    onTap: config.onTap,
    onDoubleTap: config.onDoubleTap,
    onLongPress: config.onLongPress,
    onTapDown: config.onTapDown,
    onTapUp: config.onTapUp,
    onTapCancel: config.onTapCancel,
    onPanStart: config.onPanStart,
    onPanUpdate: config.onPanUpdate,
    onPanEnd: config.onPanEnd,
    onPanCancel: config.onPanCancel,
    child: child,
  );
}
