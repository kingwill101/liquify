import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class DismissibleTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  DismissibleTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildDismissible(evaluator, namedValues, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildDismissible(evaluator, namedValues, config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('dismissible').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('enddismissible').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'dismissible',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _DismissibleConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _DismissibleConfig();
    String? widgetIdValue;
    String? widgetKeyValue;
    Object? childValue;
    Object? backgroundValue;
    Object? secondaryBackgroundValue;
    Object? onDismissedValue;
    Object? onResizeValue;
    Object? onUpdateValue;
    Object? confirmValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        case 'background':
          backgroundValue = value;
          namedValues[name] = value;
          break;
        case 'secondaryBackground':
          secondaryBackgroundValue = value;
          namedValues[name] = value;
          break;
        case 'direction':
        case 'dismissDirection':
          config.direction = parseDismissDirection(value);
          break;
        case 'resizeDuration':
          config.resizeDuration = parseDuration(value);
          break;
        case 'movementDuration':
          config.movementDuration = parseDuration(value);
          break;
        case 'crossAxisEndOffset':
          config.crossAxisEndOffset = toDouble(value);
          break;
        case 'confirmDismiss':
          confirmValue = value;
          break;
        case 'onDismissed':
          onDismissedValue = value;
          break;
        case 'onResize':
          onResizeValue = value;
          break;
        case 'onUpdate':
          onUpdateValue = value;
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        default:
          handleUnknownArg('dismissible', name);
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

    final resolvedBackground = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'background',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedBackground != null) {
      config.background = resolvedBackground;
    } else if (backgroundValue != null) {
      config.background = backgroundValue is Widget
          ? backgroundValue
          : resolveTextWidget(backgroundValue);
    }

    final resolvedSecondary = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'secondaryBackground',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedSecondary != null) {
      config.secondaryBackground = resolvedSecondary;
    } else if (secondaryBackgroundValue != null) {
      config.secondaryBackground = secondaryBackgroundValue is Widget
          ? secondaryBackgroundValue
          : resolveTextWidget(secondaryBackgroundValue);
    }

    final ids = resolveIds(
      evaluator,
      'dismissible',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;

    if (confirmValue is bool) {
      final confirmBool = confirmValue;
      config.confirmDismiss = (direction) async => confirmBool;
    }

    config.onDismissed = _wrapDismissibleCallback(
      evaluator,
      onDismissedValue,
      ids,
      'dismissed',
    );
    config.onResize = resolveActionCallback(
      evaluator,
      onResizeValue,
      event: buildWidgetEvent(
        tag: 'dismissible',
        id: ids.id,
        key: ids.keyValue,
        event: 'resize',
      ),
      actionValue: onResizeValue is String ? onResizeValue : null,
    );
    config.onUpdate = _wrapDismissUpdateCallback(
      evaluator,
      onUpdateValue,
      ids,
      'update',
    );

    return config;
  }
}

class _DismissibleConfig {
  Widget? child;
  Widget? background;
  Widget? secondaryBackground;
  DismissDirection? direction;
  Duration? resizeDuration;
  Duration? movementDuration;
  double? crossAxisEndOffset;
  Future<bool?> Function(DismissDirection)? confirmDismiss;
  DismissDirectionCallback? onDismissed;
  VoidCallback? onResize;
  DismissUpdateCallback? onUpdate;
  Key? widgetKey;
}

Widget _buildDismissible(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _DismissibleConfig config,
  List<Widget> children,
) {
  Widget? background = config.background;
  Widget? secondaryBackground = config.secondaryBackground;
  Widget child;
  if (config.child != null) {
    child = config.child!;
  } else if (children.length >= 2 && background == null) {
    background = children.first;
    child = children.length > 2
        ? Column(children: children.sublist(1))
        : children[1];
  } else {
    child = wrapChildren(children);
  }

  return Dismissible(
    key: config.widgetKey ?? ValueKey(config.hashCode.toString()),
    direction: config.direction ?? DismissDirection.endToStart,
    background: background,
    secondaryBackground: secondaryBackground,
    resizeDuration: config.resizeDuration ?? const Duration(milliseconds: 300),
    movementDuration:
        config.movementDuration ?? const Duration(milliseconds: 200),
    crossAxisEndOffset: config.crossAxisEndOffset ?? 0.0,
    confirmDismiss: config.confirmDismiss,
    onDismissed: config.onDismissed,
    onResize: config.onResize,
    onUpdate: config.onUpdate,
    child: child,
  );
}

DismissDirectionCallback? _wrapDismissibleCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'dismissible',
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

DismissUpdateCallback? _wrapDismissUpdateCallback(
  Evaluator evaluator,
  Object? value,
  ({String id, String keyValue, Key key}) ids,
  String eventName,
) {
  final action = resolveActionCallback(
    evaluator,
    value,
    event: buildWidgetEvent(
      tag: 'dismissible',
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
