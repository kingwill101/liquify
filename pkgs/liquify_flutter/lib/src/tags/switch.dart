// ignore_for_file: deprecated_member_use
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SwitchTag extends WidgetTagBase with AsyncTag {
  SwitchTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSwitch(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildSwitch(config));
  }

  _SwitchConfig _parseConfig(Evaluator evaluator) {
    final config = _SwitchConfig();
    final namedValues = <String, Object?>{};
    Object? onChangedValue;
    Object? actionValue;
    Object? onFocusChangeValue;
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
        case 'action':
          actionValue = value;
          break;
        case 'onChanged':
          onChangedValue = value;
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
        case 'trackOutlineWidth':
          config.trackOutlineWidth = toWidgetStateDouble(value);
          break;
        case 'thumbIcon':
          config.thumbIcon = toWidgetStateIcon(value);
          break;
        case 'materialTapTargetSize':
          config.materialTapTargetSize = parseMaterialTapTargetSize(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'mouseCursor':
          if (value is MouseCursor) {
            config.mouseCursor = value;
          }
          break;
        case 'focusColor':
          config.focusColor = parseColor(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'overlayColor':
          config.overlayColor = toWidgetStateColor(value);
          break;
        case 'splashRadius':
          config.splashRadius = toDouble(value);
          break;
        case 'focusNode':
          if (value is FocusNode) {
            config.focusNode = value;
          }
          break;
        case 'onFocusChange':
          onFocusChangeValue = value;
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('switch', name);
          break;
      }
    }
    config.onChanged =
        resolveBoolActionCallback(evaluator, onChangedValue) ??
            resolveBoolActionCallback(evaluator, actionValue);
    config.onFocusChange =
        resolveBoolActionCallback(evaluator, onFocusChangeValue);
    config.padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    return config;
  }
}

class _SwitchConfig {
  bool? adaptive;
  bool? value;
  ValueChanged<bool>? onChanged;
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
  WidgetStateProperty<double?>? trackOutlineWidth;
  WidgetStateProperty<Icon?>? thumbIcon;
  MaterialTapTargetSize? materialTapTargetSize;
  DragStartBehavior? dragStartBehavior;
  MouseCursor? mouseCursor;
  Color? focusColor;
  Color? hoverColor;
  WidgetStateProperty<Color?>? overlayColor;
  double? splashRadius;
  FocusNode? focusNode;
  ValueChanged<bool>? onFocusChange;
  bool? autofocus;
  EdgeInsetsGeometry? padding;
}

Widget _buildSwitch(_SwitchConfig config) {
  if (config.value == null) {
    throw Exception('switch tag requires "value"');
  }
  final isAdaptive = config.adaptive ?? false;
  if (isAdaptive) {
    return Switch.adaptive(
      value: config.value!,
      onChanged: config.onChanged,
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
      trackOutlineWidth: config.trackOutlineWidth,
      thumbIcon: config.thumbIcon,
      materialTapTargetSize: config.materialTapTargetSize,
      dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
      mouseCursor: config.mouseCursor,
      focusColor: config.focusColor,
      hoverColor: config.hoverColor,
      overlayColor: config.overlayColor,
      splashRadius: config.splashRadius,
      focusNode: config.focusNode,
      onFocusChange: config.onFocusChange,
      autofocus: config.autofocus ?? false,
      padding: config.padding,
    );
  }

  return Switch(
    value: config.value!,
    onChanged: config.onChanged,
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
    trackOutlineWidth: config.trackOutlineWidth,
    thumbIcon: config.thumbIcon,
    materialTapTargetSize: config.materialTapTargetSize,
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    mouseCursor: config.mouseCursor,
    focusColor: config.focusColor,
    hoverColor: config.hoverColor,
    overlayColor: config.overlayColor,
    splashRadius: config.splashRadius,
    focusNode: config.focusNode,
    onFocusChange: config.onFocusChange,
    autofocus: config.autofocus ?? false,
    padding: config.padding,
  );
}
