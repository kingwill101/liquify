import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class CheckboxListTileTag extends WidgetTagBase with AsyncTag {
  CheckboxListTileTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildCheckboxListTile(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildCheckboxListTile(config));
  }

  _CheckboxListTileConfig _parseConfig(Evaluator evaluator) {
    final config = _CheckboxListTileConfig();
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
        case 'tristate':
          config.tristate = toBool(value);
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
        case 'enabled':
          config.enabled = toBool(value);
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
        case 'fillColor':
          config.fillColor = toWidgetStateColor(value);
          break;
        case 'checkColor':
          config.checkColor = parseColor(value);
          break;
        case 'shape':
          config.shape = parseShapeBorder(value);
          break;
        case 'checkboxShape':
          final shape = parseShapeBorder(value);
          if (shape is OutlinedBorder) {
            config.checkboxShape = shape;
          }
          break;
        case 'side':
          config.side = parseBorderSide(value);
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
        case 'visualDensity':
          config.visualDensity = parseVisualDensity(value);
          break;
        case 'hoverColor':
          config.hoverColor = parseColor(value);
          break;
        case 'overlayColor':
          config.overlayColor = toWidgetStateColor(value);
          break;
        case 'isError':
          config.isError = toBool(value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'checkboxSemanticLabel':
          config.checkboxSemanticLabel = value?.toString();
          break;
        case 'checkboxScaleFactor':
          config.checkboxScaleFactor = toDouble(value);
          break;
        case 'titleAlignment':
          config.titleAlignment = parseListTileTitleAlignment(value);
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
          handleUnknownArg('checkbox_list_tile', name);
          break;
      }
    }

    if (config.value == null) {
      throw Exception('checkbox_list_tile tag requires "value"');
    }

    final ids = resolveIds(
      evaluator,
      'checkbox_list_tile',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    config.widgetKey = ids.key;
    final actionName = actionValue is String ? actionValue : null;
    final baseEvent = buildWidgetEvent(
      tag: 'checkbox_list_tile',
      id: ids.id,
      key: ids.keyValue,
      action: actionName,
      event: 'changed',
      props: {
        'title': config.titleLabel,
        'subtitle': config.subtitleLabel,
      },
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

class _CheckboxListTileConfig {
  bool? adaptive;
  bool? value;
  bool? tristate;
  Widget? title;
  String? titleLabel;
  Widget? subtitle;
  String? subtitleLabel;
  Widget? secondary;
  bool? isThreeLine;
  bool? dense;
  bool? enabled;
  bool? selected;
  EdgeInsetsGeometry? contentPadding;
  ListTileControlAffinity? controlAffinity;
  Color? activeColor;
  WidgetStateProperty<Color?>? fillColor;
  Color? checkColor;
  ShapeBorder? shape;
  OutlinedBorder? checkboxShape;
  BorderSide? side;
  Color? tileColor;
  Color? selectedTileColor;
  Color? hoverColor;
  WidgetStateProperty<Color?>? overlayColor;
  double? splashRadius;
  MaterialTapTargetSize? materialTapTargetSize;
  VisualDensity? visualDensity;
  MouseCursor? mouseCursor;
  FocusNode? focusNode;
  bool? autofocus;
  ValueChanged<bool>? onFocusChange;
  bool? enableFeedback;
  ValueChanged<bool>? onChanged;
  Key? widgetKey;
  bool? isError;
  String? checkboxSemanticLabel;
  double? checkboxScaleFactor;
  ListTileTitleAlignment? titleAlignment;
  bool? internalAddSemanticForOnTap;
}

Widget _buildCheckboxListTile(_CheckboxListTileConfig config) {
  final useAdaptive = config.adaptive ?? false;
  if (useAdaptive) {
    return CheckboxListTile.adaptive(
      key: config.widgetKey,
      value: config.value,
      tristate: config.tristate ?? false,
      onChanged: config.onChanged == null
          ? null
          : (value) {
              if (value != null) {
                config.onChanged!(value);
              }
            },
      title: config.title,
      subtitle: config.subtitle,
      secondary: config.secondary,
      isThreeLine: config.isThreeLine,
      dense: config.dense,
      enabled: config.enabled,
      contentPadding: config.contentPadding,
      controlAffinity: config.controlAffinity,
      activeColor: config.activeColor,
      fillColor: config.fillColor,
      checkColor: config.checkColor,
      shape: config.shape,
      checkboxShape: config.checkboxShape,
      side: config.side,
      tileColor: config.tileColor,
      selectedTileColor: config.selectedTileColor,
      hoverColor: config.hoverColor,
      overlayColor: config.overlayColor,
      splashRadius: config.splashRadius,
      materialTapTargetSize: config.materialTapTargetSize,
      visualDensity: config.visualDensity,
      mouseCursor: config.mouseCursor,
      focusNode: config.focusNode,
      autofocus: config.autofocus ?? false,
      onFocusChange: config.onFocusChange,
      enableFeedback: config.enableFeedback,
      selected: config.selected ?? false,
      isError: config.isError ?? false,
      checkboxSemanticLabel: config.checkboxSemanticLabel,
      checkboxScaleFactor: config.checkboxScaleFactor ?? 1.0,
      titleAlignment: config.titleAlignment,
      internalAddSemanticForOnTap: config.internalAddSemanticForOnTap ?? false,
    );
  }
  return CheckboxListTile(
    key: config.widgetKey,
    value: config.value,
    tristate: config.tristate ?? false,
    onChanged: config.onChanged == null
        ? null
        : (value) {
            if (value != null) {
              config.onChanged!(value);
            }
          },
    title: config.title,
    subtitle: config.subtitle,
    secondary: config.secondary,
    isThreeLine: config.isThreeLine ?? false,
    dense: config.dense,
    enabled: config.enabled,
    contentPadding: config.contentPadding,
    controlAffinity: config.controlAffinity,
    activeColor: config.activeColor,
    fillColor: config.fillColor,
    checkColor: config.checkColor,
    shape: config.shape,
    checkboxShape: config.checkboxShape,
    side: config.side,
    tileColor: config.tileColor,
    selectedTileColor: config.selectedTileColor,
    hoverColor: config.hoverColor,
    overlayColor: config.overlayColor,
    splashRadius: config.splashRadius,
    materialTapTargetSize: config.materialTapTargetSize,
    visualDensity: config.visualDensity,
    mouseCursor: config.mouseCursor,
    focusNode: config.focusNode,
    autofocus: config.autofocus ?? false,
    onFocusChange: config.onFocusChange,
    enableFeedback: config.enableFeedback,
    selected: config.selected ?? false,
    isError: config.isError ?? false,
    checkboxSemanticLabel: config.checkboxSemanticLabel,
    checkboxScaleFactor: config.checkboxScaleFactor ?? 1.0,
    titleAlignment: config.titleAlignment,
    internalAddSemanticForOnTap: config.internalAddSemanticForOnTap ?? false,
  );
}

String? _stringValue(Object? value) {
  if (value == null || value is Widget) {
    return null;
  }
  return value.toString();
}
