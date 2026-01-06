import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class PopupMenuSpec {
  final List<PopupMenuEntry<String>> items = [];
}

const String _popupMenuSpecKey = '_liquify_flutter_popup_menu_spec';

PopupMenuSpec? getPopupMenuSpec(Environment environment) {
  final value = environment.getRegister(_popupMenuSpecKey);
  if (value is PopupMenuSpec) {
    return value;
  }
  return null;
}

void setPopupMenuSpec(Environment environment, PopupMenuSpec? spec) {
  if (spec == null) {
    environment.removeRegister(_popupMenuSpecKey);
  } else {
    environment.setRegister(_popupMenuSpecKey, spec);
  }
}

PopupMenuSpec requirePopupMenuSpec(Evaluator evaluator, String tagName) {
  final spec = getPopupMenuSpec(evaluator.context);
  if (spec == null) {
    throw Exception('$tagName tag must be used inside popup_menu');
  }
  return spec;
}

class PopupMenuTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  PopupMenuTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final items = _captureItemsSync(evaluator);
    buffer.write(_buildPopupMenu(config, items));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final items = await _captureItemsAsync(evaluator);
    buffer.write(_buildPopupMenu(config, items));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('popup_menu').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endpopup_menu').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'popup_menu',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _PopupMenuConfig _parseConfig(Evaluator evaluator) {
    final config = _PopupMenuConfig();
    Object? actionValue;
    Object? onSelectedValue;
    Object? onCanceledValue;
    String? widgetIdValue;
    String? widgetKeyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'tooltip':
          config.tooltip = value?.toString();
          break;
        case 'elevation':
          config.elevation = toDouble(value);
          break;
        case 'color':
        case 'backgroundColor':
          config.color = parseColor(value);
          break;
        case 'padding':
          config.padding = parseEdgeInsetsGeometry(value);
          break;
        case 'offset':
          config.offset = parseOffset(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'enabled':
          config.enabled = toBool(value);
          break;
        case 'initialValue':
          config.initialValue = value?.toString();
          break;
        case 'icon':
          config.icon = resolveIconWidget(value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onSelected':
          onSelectedValue = value;
          break;
        case 'onCanceled':
          onCanceledValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('popup_menu', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'popup_menu',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final resolvedKeyValue =
        (widgetKeyValue != null && widgetKeyValue.trim().isNotEmpty)
            ? widgetKeyValue.trim()
            : resolvedId;
    config.widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'popup_menu',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'selected',
      props: const {},
    );
    final selectedCallback =
        resolveStringActionCallback(
              evaluator,
              onSelectedValue,
              event: baseEvent,
              actionValue: actionName,
            ) ??
            resolveStringActionCallback(
              evaluator,
              actionValue,
              event: baseEvent,
              actionValue: actionName,
            );
    config.onSelected = selectedCallback == null
        ? null
        : (value) {
            baseEvent['value'] = value;
            selectedCallback(value);
          };
    final cancelEvent = buildWidgetEvent(
      tag: 'popup_menu',
      id: resolvedId,
      key: resolvedKeyValue,
      action: actionName,
      event: 'canceled',
      props: const {},
    );
    config.onCanceled = resolveActionCallback(
      evaluator,
      onCanceledValue,
      event: cancelEvent,
      actionValue: actionName,
    );
    return config;
  }

  List<PopupMenuEntry<String>> _captureItemsSync(Evaluator evaluator) {
    final previous = getPopupMenuSpec(evaluator.context);
    final spec = PopupMenuSpec();
    setPopupMenuSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      evaluator.popBufferValue();
      return spec.items;
    } finally {
      setPopupMenuSpec(evaluator.context, previous);
    }
  }

  Future<List<PopupMenuEntry<String>>> _captureItemsAsync(
    Evaluator evaluator,
  ) async {
    final previous = getPopupMenuSpec(evaluator.context);
    final spec = PopupMenuSpec();
    setPopupMenuSpec(evaluator.context, spec);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      evaluator.popBufferValue();
      return spec.items;
    } finally {
      setPopupMenuSpec(evaluator.context, previous);
    }
  }
}

class PopupMenuItemTag extends WidgetTagBase with AsyncTag {
  PopupMenuItemTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final entry = _buildEntry(evaluator);
    requirePopupMenuSpec(evaluator, 'popup_menu_item').items.add(entry);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final entry = _buildEntry(evaluator);
    requirePopupMenuSpec(evaluator, 'popup_menu_item').items.add(entry);
  }

  PopupMenuEntry<String> _buildEntry(Evaluator evaluator) {
    String? label;
    String? value;
    bool? enabled;
    double? height;
    EdgeInsetsGeometry? padding;
    Widget? child;
    Widget? icon;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final evaluated = evaluator.evaluate(arg.value);
      switch (name) {
        case 'label':
          label = evaluated?.toString();
          break;
        case 'value':
          value = evaluated?.toString();
          break;
        case 'enabled':
          enabled = toBool(evaluated);
          break;
        case 'height':
          height = toDouble(evaluated);
          break;
        case 'padding':
          padding = parseEdgeInsetsGeometry(evaluated);
          break;
        case 'icon':
          icon = resolveIconWidget(evaluated);
          break;
        case 'child':
          if (evaluated is Widget) {
            child = evaluated;
          }
          break;
        default:
          handleUnknownArg('popup_menu_item', name);
          break;
      }
    }

    final resolvedValue = value ?? label ?? '';
    Widget resolvedChild = child ?? Text(label ?? resolvedValue);
    if (icon != null) {
      resolvedChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: resolvedChild),
        ],
      );
    }
    final resolvedHeight = height ?? kMinInteractiveDimension;
    final resolvedPadding = padding as EdgeInsets?;
    return PopupMenuItem<String>(
      value: resolvedValue,
      enabled: enabled ?? true,
      height: resolvedHeight,
      padding: resolvedPadding,
      child: resolvedChild,
    );
  }
}

class PopupMenuDividerTag extends WidgetTagBase with AsyncTag {
  PopupMenuDividerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final entry = _buildDivider(evaluator);
    requirePopupMenuSpec(evaluator, 'popup_menu_divider').items.add(entry);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final entry = _buildDivider(evaluator);
    requirePopupMenuSpec(evaluator, 'popup_menu_divider').items.add(entry);
  }

  PopupMenuDivider _buildDivider(Evaluator evaluator) {
    double? height;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'height':
          height = toDouble(value);
          break;
        default:
          handleUnknownArg('popup_menu_divider', name);
          break;
      }
    }
    return PopupMenuDivider(height: height ?? kMinInteractiveDimension);
  }
}

class _PopupMenuConfig {
  String? tooltip;
  double? elevation;
  Color? color;
  EdgeInsetsGeometry? padding;
  Offset? offset;
  ShapeBorder? shape;
  bool? enabled;
  String? initialValue;
  Widget? icon;
  Widget? child;
  ValueChanged<String>? onSelected;
  VoidCallback? onCanceled;
  Key? widgetKey;
}

Widget _buildPopupMenu(
  _PopupMenuConfig config,
  List<PopupMenuEntry<String>> items,
) {
  return PopupMenuButton<String>(
    key: config.widgetKey,
    tooltip: config.tooltip,
    elevation: config.elevation,
    color: config.color,
    padding: config.padding ?? const EdgeInsets.all(8),
    offset: config.offset ?? Offset.zero,
    shape: config.shape,
    enabled: config.enabled ?? true,
    initialValue: config.initialValue,
    icon: config.icon,
    onSelected: config.onSelected,
    onCanceled: config.onCanceled,
    itemBuilder: (context) => items,
    child: config.child,
  );
}
