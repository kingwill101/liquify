// ignore_for_file: deprecated_member_use
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SwitchListTileTag extends WidgetTagBase with AsyncTag {
  SwitchListTileTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSwitchListTile(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSwitchListTile(config));
  }

  _SwitchListTileConfig _parseConfig(Evaluator evaluator) {
    final config = _SwitchListTileConfig();
    Object? actionValue;
    Object? onChangedValue;
    Object? onFocusChangeValue;
    String? widgetIdValue;
    String? widgetKeyValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'adaptive':
          config.adaptive = toBool(value);
          break;
        case 'value':
          config.value = toBool(value);
          break;
        case 'title':
          config.titleLabel = _stringValue(value);
          config.title = resolveTextWidget(value);
          break;
        case 'subtitle':
          config.subtitleLabel = _stringValue(value);
          config.subtitle = resolveTextWidget(value);
          break;
        case 'secondary':
          config.secondary = resolveIconWidget(value);
          break;
        case 'isThreeLine':
          config.isThreeLine = toBool(value);
          break;
        case 'dense':
          config.dense = toBool(value);
          break;
        case 'selected':
          config.selected = toBool(value);
          break;
        case 'contentPadding':
          config.contentPadding = parseEdgeInsetsGeometry(value);
          break;
        case 'tileColor':
          config.tileColor = parseColor(value);
          break;
        case 'selectedTileColor':
          config.selectedTileColor = parseColor(value);
          break;
        case 'controlAffinity':
          config.controlAffinity = parseListTileControlAffinity(value);
          break;
        case 'activeColor':
          config.activeColor = parseColor(value);
          break;
        case 'activeThumbColor':
          config.activeThumbColor = parseColor(value);
          break;
        case 'activeTrackColor':
          config.activeTrackColor = parseColor(value);
          break;
        case 'inactiveThumbColor':
          config.inactiveThumbColor = parseColor(value);
          break;
        case 'inactiveTrackColor':
          config.inactiveTrackColor = parseColor(value);
          break;
        case 'activeThumbImage':
          if (value is ImageProvider) {
            config.activeThumbImage = value;
          }
          break;
        case 'onActiveThumbImageError':
          if (value is ImageErrorListener) {
            config.onActiveThumbImageError = value;
          }
          break;
        case 'inactiveThumbImage':
          if (value is ImageProvider) {
            config.inactiveThumbImage = value;
          }
          break;
        case 'onInactiveThumbImageError':
          if (value is ImageErrorListener) {
            config.onInactiveThumbImageError = value;
          }
          break;
        case 'thumbColor':
          config.thumbColor = toWidgetStateColor(value);
          break;
        case 'trackColor':
          config.trackColor = toWidgetStateColor(value);
          break;
        case 'trackOutlineColor':
          config.trackOutlineColor = toWidgetStateColor(value);
          break;
        case 'thumbIcon':
          config.thumbIcon = toWidgetStateIcon(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'mouseCursor':
          config.mouseCursor = parseMouseCursor(value) ?? config.mouseCursor;
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'focusNode':
          if (value is FocusNode) {
            config.focusNode = value;
          }
          break;
        case 'onFocusChange':
          onFocusChangeValue = value;
          break;
        case 'splashRadius':
          config.splashRadius = toDouble(value);
          break;
        case 'materialTapTargetSize':
          config.materialTapTargetSize = parseMaterialTapTargetSize(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'visualDensity':
          config.visualDensity = parseVisualDensity(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'overlayColor':
          config.overlayColor = toWidgetStateColor(value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'applyCupertinoTheme':
          config.applyCupertinoTheme = toBool(value);
          break;
        case 'internalAddSemanticForOnTap':
          config.internalAddSemanticForOnTap = toBool(value);
          break;
        case 'action':
          actionValue = value;
          break;
        case 'onChanged':
          onChangedValue = value;
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('switch_list_tile', name);
          break;
      }
    }

    if (config.value == null) {
      throw Exception('switch_list_tile tag requires "value"');
    }

    final ids = resolveIds(
      evaluator,
      'switch_list_tile',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'switch_list_tile',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'changed',
      props: {'title': config.titleLabel, 'subtitle': config.subtitleLabel},
    );
    final callback =
        resolveBoolActionCallback(
          evaluator,
          onChangedValue,
          event: baseEvent,
          actionValue: actionName,
        ) ??
        resolveBoolActionCallback(
          evaluator,
          actionValue,
          event: baseEvent,
          actionValue: actionName,
        );
    if (callback != null) {
      config.onChanged = (value) {
        baseEvent['value'] = value;
        callback(value);
      };
    }
    config.onFocusChange = resolveBoolActionCallback(
      evaluator,
      onFocusChangeValue,
    );
    return config;
  }
}

class _SwitchListTileConfig {
  bool? adaptive;
  bool? value;
  Widget? title;
  String? titleLabel;
  Widget? subtitle;
  String? subtitleLabel;
  Widget? secondary;
  bool? isThreeLine;
  bool? dense;
  bool? selected;
  EdgeInsetsGeometry? contentPadding;
  ListTileControlAffinity? controlAffinity;
  Color? activeColor;
  Color? activeThumbColor;
  Color? activeTrackColor;
  Color? inactiveThumbColor;
  Color? inactiveTrackColor;
  ImageProvider? activeThumbImage;
  ImageErrorListener? onActiveThumbImageError;
  ImageProvider? inactiveThumbImage;
  ImageErrorListener? onInactiveThumbImageError;
  WidgetStateProperty<Color?>? thumbColor;
  WidgetStateProperty<Color?>? trackColor;
  WidgetStateProperty<Color?>? trackOutlineColor;
  WidgetStateProperty<Icon?>? thumbIcon;
  ShapeBorder? shape;
  Color? tileColor;
  Color? selectedTileColor;
  Color? hoverColor;
  WidgetStateProperty<Color?>? overlayColor;
  double? splashRadius;
  MaterialTapTargetSize? materialTapTargetSize;
  DragStartBehavior? dragStartBehavior;
  VisualDensity? visualDensity;
  MouseCursor? mouseCursor;
  FocusNode? focusNode;
  bool? autofocus;
  ValueChanged<bool>? onFocusChange;
  bool? enableFeedback;
  ValueChanged<bool>? onChanged;
  Key? widgetKey;
  bool? applyCupertinoTheme;
  bool? internalAddSemanticForOnTap;
}

Widget _buildSwitchListTile(_SwitchListTileConfig config) {
  final useAdaptive = config.adaptive ?? false;
  if (useAdaptive) {
    return SwitchListTile.adaptive(
      key: config.widgetKey,
      value: config.value ?? false,
      onChanged: config.onChanged,
      title: config.title,
      subtitle: config.subtitle,
      secondary: config.secondary,
      isThreeLine: config.isThreeLine,
      dense: config.dense,
      contentPadding: config.contentPadding,
      controlAffinity: config.controlAffinity,
      activeColor: config.activeColor,
      activeThumbColor: config.activeThumbColor,
      activeTrackColor: config.activeTrackColor,
      inactiveThumbColor: config.inactiveThumbColor,
      inactiveTrackColor: config.inactiveTrackColor,
      activeThumbImage: config.activeThumbImage,
      onActiveThumbImageError: config.onActiveThumbImageError,
      inactiveThumbImage: config.inactiveThumbImage,
      onInactiveThumbImageError: config.onInactiveThumbImageError,
      thumbColor: config.thumbColor,
      trackColor: config.trackColor,
      trackOutlineColor: config.trackOutlineColor,
      thumbIcon: config.thumbIcon,
      shape: config.shape,
      tileColor: config.tileColor,
      selectedTileColor: config.selectedTileColor,
      hoverColor: config.hoverColor,
      overlayColor: config.overlayColor,
      splashRadius: config.splashRadius,
      materialTapTargetSize: config.materialTapTargetSize,
      dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
      visualDensity: config.visualDensity,
      mouseCursor: config.mouseCursor,
      focusNode: config.focusNode,
      autofocus: config.autofocus ?? false,
      onFocusChange: config.onFocusChange,
      enableFeedback: config.enableFeedback,
      selected: config.selected ?? false,
      applyCupertinoTheme: config.applyCupertinoTheme,
      internalAddSemanticForOnTap: config.internalAddSemanticForOnTap ?? false,
    );
  }
  return SwitchListTile(
    key: config.widgetKey,
    value: config.value ?? false,
    onChanged: config.onChanged,
    title: config.title,
    subtitle: config.subtitle,
    secondary: config.secondary,
    isThreeLine: config.isThreeLine ?? false,
    dense: config.dense,
    contentPadding: config.contentPadding,
    controlAffinity: config.controlAffinity,
    activeColor: config.activeColor,
    activeThumbColor: config.activeThumbColor,
    activeTrackColor: config.activeTrackColor,
    inactiveThumbColor: config.inactiveThumbColor,
    inactiveTrackColor: config.inactiveTrackColor,
    activeThumbImage: config.activeThumbImage,
    onActiveThumbImageError: config.onActiveThumbImageError,
    inactiveThumbImage: config.inactiveThumbImage,
    onInactiveThumbImageError: config.onInactiveThumbImageError,
    thumbColor: config.thumbColor,
    trackColor: config.trackColor,
    trackOutlineColor: config.trackOutlineColor,
    thumbIcon: config.thumbIcon,
    shape: config.shape,
    tileColor: config.tileColor,
    selectedTileColor: config.selectedTileColor,
    hoverColor: config.hoverColor,
    overlayColor: config.overlayColor,
    splashRadius: config.splashRadius,
    materialTapTargetSize: config.materialTapTargetSize,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    visualDensity: config.visualDensity,
    mouseCursor: config.mouseCursor,
    focusNode: config.focusNode,
    autofocus: config.autofocus ?? false,
    onFocusChange: config.onFocusChange,
    enableFeedback: config.enableFeedback,
    selected: config.selected ?? false,
    internalAddSemanticForOnTap: config.internalAddSemanticForOnTap ?? false,
  );
}

String? _stringValue(Object? value) {
  if (value == null || value is Widget) {
    return null;
  }
  return value.toString();
}
