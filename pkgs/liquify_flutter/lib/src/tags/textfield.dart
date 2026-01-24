// ignore_for_file: deprecated_member_use
import 'dart:ui' show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TextFieldTag extends WidgetTagBase with AsyncTag {
  TextFieldTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildTextField(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildTextField(config));
  }

  _TextFieldConfig _parseConfig(Evaluator evaluator) {
    final config = _TextFieldConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'groupId':
          config.groupId = value;
          break;
        case 'controller':
          if (value is TextEditingController) {
            config.controller = value;
          }
          break;
        case 'focusNode':
          if (value is FocusNode) {
            config.focusNode = value;
          }
          break;
        case 'undoController':
          if (value is UndoHistoryController) {
            config.undoController = value;
          }
          break;
        case 'decoration':
          config.decorationProvided = true;
          if (value == null || value is InputDecoration) {
            config.decoration = value as InputDecoration?;
          }
          break;
        case 'label':
        case 'labelText':
          config.label = value?.toString();
          break;
        case 'hint':
        case 'hintText':
          config.hint = value?.toString();
          break;
        case 'keyboardType':
          config.keyboardType = parseTextInputType(value);
          break;
        case 'textInputAction':
          config.textInputAction = parseTextInputAction(value);
          break;
        case 'textCapitalization':
          config.textCapitalization = parseTextCapitalization(value);
          break;
        case 'style':
          if (value is TextStyle) {
            config.style = value;
          }
          break;
        case 'strutStyle':
          if (value is StrutStyle) {
            config.strutStyle = value;
          }
          break;
        case 'textAlign':
        case 'align':
          config.textAlign = parseTextAlign(value);
          break;
        case 'textAlignVertical':
          config.textAlignVertical = parseTextAlignVertical(value);
          break;
        case 'textDirection':
          config.textDirection = parseTextDirection(value);
          break;
        case 'readOnly':
          config.readOnly = toBool(value);
          break;
        case 'toolbarOptions':
          if (value is ToolbarOptions) {
            config.toolbarOptions = value;
          }
          break;
        case 'showCursor':
          config.showCursor = toBool(value);
          break;
        case 'autofocus':
          config.autofocus = toBool(value);
          break;
        case 'statesController':
          if (value is MaterialStatesController) {
            config.statesController = value;
          }
          break;
        case 'obscuringCharacter':
          config.obscuringCharacter = value?.toString();
          break;
        case 'obscure':
        case 'obscureText':
          config.obscureText = toBool(value);
          break;
        case 'autocorrect':
          config.autocorrect = toBool(value);
          break;
        case 'smartDashesType':
          config.smartDashesType = parseSmartDashesType(value);
          break;
        case 'smartQuotesType':
          config.smartQuotesType = parseSmartQuotesType(value);
          break;
        case 'enableSuggestions':
          config.enableSuggestions = toBool(value);
          break;
        case 'maxLines':
          config.maxLines = toInt(value);
          break;
        case 'minLines':
          config.minLines = toInt(value);
          break;
        case 'expands':
          config.expands = toBool(value);
          break;
        case 'maxLength':
          config.maxLength = toInt(value);
          break;
        case 'maxLengthEnforcement':
          config.maxLengthEnforcement = parseMaxLengthEnforcement(value);
          break;
        case 'onChanged':
          config.onChanged = resolveStringActionCallback(evaluator, value);
          break;
        case 'onEditingComplete':
          config.onEditingComplete = resolveActionCallback(evaluator, value);
          break;
        case 'onSubmitted':
          config.onSubmitted = resolveStringActionCallback(evaluator, value);
          break;
        case 'onAppPrivateCommand':
          if (value is AppPrivateCommandCallback) {
            config.onAppPrivateCommand = value;
          }
          break;
        case 'inputFormatters':
          if (value is List<TextInputFormatter>) {
            config.inputFormatters = value;
          } else if (value is Iterable) {
            final formatters = <TextInputFormatter>[];
            for (final entry in value) {
              if (entry is TextInputFormatter) {
                formatters.add(entry);
              }
            }
            config.inputFormatters = formatters;
          }
          break;
        case 'enabled':
          config.enabled = toBool(value);
          break;
        case 'ignorePointers':
          config.ignorePointers = toBool(value);
          break;
        case 'cursorWidth':
          config.cursorWidth = toDouble(value);
          break;
        case 'cursorHeight':
          config.cursorHeight = toDouble(value);
          break;
        case 'cursorRadius':
          if (value is Radius) {
            config.cursorRadius = value;
          } else {
            final radius = toDouble(value);
            if (radius != null) {
              config.cursorRadius = Radius.circular(radius);
            }
          }
          break;
        case 'cursorOpacityAnimates':
          config.cursorOpacityAnimates = toBool(value);
          break;
        case 'cursorColor':
          config.cursorColor = parseColor(value);
          break;
        case 'cursorErrorColor':
          config.cursorErrorColor = parseColor(value);
          break;
        case 'selectionHeightStyle':
          config.selectionHeightStyle = parseBoxHeightStyle(value);
          break;
        case 'selectionWidthStyle':
          config.selectionWidthStyle = parseBoxWidthStyle(value);
          break;
        case 'keyboardAppearance':
          config.keyboardAppearance = parseBrightness(value);
          break;
        case 'scrollPadding':
          config.scrollPadding = _edgeInsetsAsInsets(value);
          break;
        case 'dragStartBehavior':
          config.dragStartBehavior = parseDragStartBehavior(value);
          break;
        case 'enableInteractiveSelection':
          config.enableInteractiveSelection = toBool(value);
          break;
        case 'selectAllOnFocus':
          config.selectAllOnFocus = toBool(value);
          break;
        case 'selectionControls':
          if (value is TextSelectionControls) {
            config.selectionControls = value;
          }
          break;
        case 'onTap':
          config.onTap = resolveActionCallback(evaluator, value);
          break;
        case 'onTapAlwaysCalled':
          config.onTapAlwaysCalled = toBool(value);
          break;
        case 'onTapOutside':
          if (value is TapRegionCallback) {
            config.onTapOutside = value;
          }
          break;
        case 'onTapUpOutside':
          if (value is TapRegionUpCallback) {
            config.onTapUpOutside = value;
          }
          break;
        case 'mouseCursor':
          if (value is MouseCursor) {
            config.mouseCursor = value;
          }
          break;
        case 'buildCounter':
          if (value is InputCounterWidgetBuilder) {
            config.buildCounter = value;
          }
          break;
        case 'scrollController':
          if (value is ScrollController) {
            config.scrollController = value;
          }
          break;
        case 'scrollPhysics':
          config.scrollPhysics = parseScrollPhysics(value);
          break;
        case 'autofillHints':
          config.autofillHints = _parseAutofillHints(value);
          break;
        case 'contentInsertionConfiguration':
          if (value is ContentInsertionConfiguration) {
            config.contentInsertionConfiguration = value;
          }
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'restorationId':
          config.restorationId = value?.toString();
          break;
        case 'scribbleEnabled':
          config.scribbleEnabled = toBool(value);
          break;
        case 'stylusHandwritingEnabled':
          config.stylusHandwritingEnabled = toBool(value);
          break;
        case 'enableIMEPersonalizedLearning':
          config.enableIMEPersonalizedLearning = toBool(value);
          break;
        case 'contextMenuBuilder':
          config.contextMenuBuilderProvided = true;
          if (value == null || value is EditableTextContextMenuBuilder) {
            config.contextMenuBuilder = value as EditableTextContextMenuBuilder?;
          }
          break;
        case 'canRequestFocus':
          config.canRequestFocus = toBool(value);
          break;
        case 'spellCheckConfiguration':
          if (value is SpellCheckConfiguration) {
            config.spellCheckConfiguration = value;
          }
          break;
        case 'magnifierConfiguration':
          if (value is TextMagnifierConfiguration) {
            config.magnifierConfiguration = value;
          }
          break;
        case 'hintLocales':
          config.hintLocales = _parseLocales(value);
          break;
        default:
          handleUnknownArg('textfield', name);
          break;
      }
    }
    return config;
  }
}

class _TextFieldConfig {
  Object? groupId;
  TextEditingController? controller;
  FocusNode? focusNode;
  UndoHistoryController? undoController;
  bool decorationProvided = false;
  InputDecoration? decoration;
  String? label;
  String? hint;
  TextInputType? keyboardType;
  TextInputAction? textInputAction;
  TextCapitalization? textCapitalization;
  TextStyle? style;
  StrutStyle? strutStyle;
  TextAlign? textAlign;
  TextAlignVertical? textAlignVertical;
  TextDirection? textDirection;
  bool? readOnly;
  ToolbarOptions? toolbarOptions;
  bool? showCursor;
  bool? autofocus;
  MaterialStatesController? statesController;
  String? obscuringCharacter;
  bool? obscureText;
  bool? autocorrect;
  SmartDashesType? smartDashesType;
  SmartQuotesType? smartQuotesType;
  bool? enableSuggestions;
  int? maxLines;
  int? minLines;
  bool? expands;
  int? maxLength;
  MaxLengthEnforcement? maxLengthEnforcement;
  ValueChanged<String>? onChanged;
  VoidCallback? onEditingComplete;
  ValueChanged<String>? onSubmitted;
  AppPrivateCommandCallback? onAppPrivateCommand;
  List<TextInputFormatter>? inputFormatters;
  bool? enabled;
  bool? ignorePointers;
  double? cursorWidth;
  double? cursorHeight;
  Radius? cursorRadius;
  bool? cursorOpacityAnimates;
  Color? cursorColor;
  Color? cursorErrorColor;
  BoxHeightStyle? selectionHeightStyle;
  BoxWidthStyle? selectionWidthStyle;
  Brightness? keyboardAppearance;
  EdgeInsets? scrollPadding;
  DragStartBehavior? dragStartBehavior;
  bool? enableInteractiveSelection;
  bool? selectAllOnFocus;
  TextSelectionControls? selectionControls;
  GestureTapCallback? onTap;
  bool? onTapAlwaysCalled;
  TapRegionCallback? onTapOutside;
  TapRegionUpCallback? onTapUpOutside;
  MouseCursor? mouseCursor;
  InputCounterWidgetBuilder? buildCounter;
  ScrollController? scrollController;
  ScrollPhysics? scrollPhysics;
  Iterable<String>? autofillHints;
  ContentInsertionConfiguration? contentInsertionConfiguration;
  Clip? clipBehavior;
  String? restorationId;
  bool? scribbleEnabled;
  bool? stylusHandwritingEnabled;
  bool? enableIMEPersonalizedLearning;
  bool contextMenuBuilderProvided = false;
  EditableTextContextMenuBuilder? contextMenuBuilder;
  bool? canRequestFocus;
  SpellCheckConfiguration? spellCheckConfiguration;
  TextMagnifierConfiguration? magnifierConfiguration;
  List<Locale>? hintLocales;
}

TextField _buildTextField(_TextFieldConfig config) {
  final obscureText = config.obscureText ?? false;
  final readOnly = config.readOnly ?? false;
  final maxLines = config.maxLines ?? 1;
  final keyboardType =
      config.keyboardType ?? (maxLines == 1 ? TextInputType.text : TextInputType.multiline);
  final smartDashesType = config.smartDashesType ??
      (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled);
  final smartQuotesType = config.smartQuotesType ??
      (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled);
  final enableInteractiveSelection = config.enableInteractiveSelection ??
      (!readOnly || !obscureText);
  InputDecoration? decoration = config.decoration;
  if (!config.decorationProvided) {
    if (config.label != null || config.hint != null) {
      decoration = InputDecoration(
        labelText: config.label,
        hintText: config.hint,
      );
    } else {
      decoration = const InputDecoration();
    }
  } else if (decoration != null && (config.label != null || config.hint != null)) {
    decoration = decoration.copyWith(
      labelText: config.label,
      hintText: config.hint,
    );
  }

  if (config.contextMenuBuilderProvided) {
    return TextField(
      groupId: config.groupId ?? EditableText,
      controller: config.controller,
      focusNode: config.focusNode,
      undoController: config.undoController,
      decoration: decoration,
      keyboardType: keyboardType,
      textInputAction: config.textInputAction,
      textCapitalization: config.textCapitalization ?? TextCapitalization.none,
      style: config.style,
      strutStyle: config.strutStyle,
      textAlign: config.textAlign ?? TextAlign.start,
      textAlignVertical: config.textAlignVertical,
      textDirection: config.textDirection,
      readOnly: readOnly,
      toolbarOptions: config.toolbarOptions,
      showCursor: config.showCursor,
      autofocus: config.autofocus ?? false,
      statesController: config.statesController,
      obscuringCharacter: config.obscuringCharacter ?? '•',
      obscureText: obscureText,
      autocorrect: config.autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: config.enableSuggestions ?? true,
      maxLines: maxLines,
      minLines: config.minLines,
      expands: config.expands ?? false,
      maxLength: config.maxLength,
      maxLengthEnforcement: config.maxLengthEnforcement,
      onChanged: config.onChanged,
      onEditingComplete: config.onEditingComplete,
      onSubmitted: config.onSubmitted,
      onAppPrivateCommand: config.onAppPrivateCommand,
      inputFormatters: config.inputFormatters,
      enabled: config.enabled,
      ignorePointers: config.ignorePointers,
      cursorWidth: config.cursorWidth ?? 2.0,
      cursorHeight: config.cursorHeight,
      cursorRadius: config.cursorRadius,
      cursorOpacityAnimates: config.cursorOpacityAnimates,
      cursorColor: config.cursorColor,
      cursorErrorColor: config.cursorErrorColor,
      selectionHeightStyle: config.selectionHeightStyle,
      selectionWidthStyle: config.selectionWidthStyle,
      keyboardAppearance: config.keyboardAppearance,
      scrollPadding: config.scrollPadding ?? const EdgeInsets.all(20.0),
      dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
      enableInteractiveSelection: enableInteractiveSelection,
      selectAllOnFocus: config.selectAllOnFocus,
      selectionControls: config.selectionControls,
      onTap: config.onTap,
      onTapAlwaysCalled: config.onTapAlwaysCalled ?? false,
      onTapOutside: config.onTapOutside,
      onTapUpOutside: config.onTapUpOutside,
      mouseCursor: config.mouseCursor,
      buildCounter: config.buildCounter,
      scrollController: config.scrollController,
      scrollPhysics: config.scrollPhysics,
      autofillHints: config.autofillHints ?? const <String>[],
      contentInsertionConfiguration: config.contentInsertionConfiguration,
      clipBehavior: config.clipBehavior ?? Clip.hardEdge,
      restorationId: config.restorationId,
      scribbleEnabled: config.scribbleEnabled ?? true,
      stylusHandwritingEnabled: config.stylusHandwritingEnabled ??
          EditableText.defaultStylusHandwritingEnabled,
      enableIMEPersonalizedLearning:
          config.enableIMEPersonalizedLearning ?? true,
      contextMenuBuilder: config.contextMenuBuilder,
      canRequestFocus: config.canRequestFocus ?? true,
      spellCheckConfiguration: config.spellCheckConfiguration,
      magnifierConfiguration: config.magnifierConfiguration,
      hintLocales: config.hintLocales,
    );
  }

  return TextField(
    groupId: config.groupId ?? EditableText,
    controller: config.controller,
    focusNode: config.focusNode,
    undoController: config.undoController,
    decoration: decoration,
    keyboardType: keyboardType,
    textInputAction: config.textInputAction,
    textCapitalization: config.textCapitalization ?? TextCapitalization.none,
    style: config.style,
    strutStyle: config.strutStyle,
    textAlign: config.textAlign ?? TextAlign.start,
    textAlignVertical: config.textAlignVertical,
    textDirection: config.textDirection,
    readOnly: readOnly,
    toolbarOptions: config.toolbarOptions,
    showCursor: config.showCursor,
    autofocus: config.autofocus ?? false,
    statesController: config.statesController,
    obscuringCharacter: config.obscuringCharacter ?? '•',
    obscureText: obscureText,
    autocorrect: config.autocorrect,
    smartDashesType: smartDashesType,
    smartQuotesType: smartQuotesType,
    enableSuggestions: config.enableSuggestions ?? true,
    maxLines: maxLines,
    minLines: config.minLines,
    expands: config.expands ?? false,
    maxLength: config.maxLength,
    maxLengthEnforcement: config.maxLengthEnforcement,
    onChanged: config.onChanged,
    onEditingComplete: config.onEditingComplete,
    onSubmitted: config.onSubmitted,
    onAppPrivateCommand: config.onAppPrivateCommand,
    inputFormatters: config.inputFormatters,
    enabled: config.enabled,
    ignorePointers: config.ignorePointers,
    cursorWidth: config.cursorWidth ?? 2.0,
    cursorHeight: config.cursorHeight,
    cursorRadius: config.cursorRadius,
    cursorOpacityAnimates: config.cursorOpacityAnimates,
    cursorColor: config.cursorColor,
    cursorErrorColor: config.cursorErrorColor,
    selectionHeightStyle: config.selectionHeightStyle,
    selectionWidthStyle: config.selectionWidthStyle,
    keyboardAppearance: config.keyboardAppearance,
    scrollPadding: config.scrollPadding ?? const EdgeInsets.all(20.0),
    dragStartBehavior: config.dragStartBehavior ?? DragStartBehavior.start,
    enableInteractiveSelection: enableInteractiveSelection,
    selectAllOnFocus: config.selectAllOnFocus,
    selectionControls: config.selectionControls,
    onTap: config.onTap,
    onTapAlwaysCalled: config.onTapAlwaysCalled ?? false,
    onTapOutside: config.onTapOutside,
    onTapUpOutside: config.onTapUpOutside,
    mouseCursor: config.mouseCursor,
    buildCounter: config.buildCounter,
    scrollController: config.scrollController,
    scrollPhysics: config.scrollPhysics,
    autofillHints: config.autofillHints ?? const <String>[],
    contentInsertionConfiguration: config.contentInsertionConfiguration,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    restorationId: config.restorationId,
    scribbleEnabled: config.scribbleEnabled ?? true,
    stylusHandwritingEnabled: config.stylusHandwritingEnabled ??
        EditableText.defaultStylusHandwritingEnabled,
    enableIMEPersonalizedLearning: config.enableIMEPersonalizedLearning ?? true,
    canRequestFocus: config.canRequestFocus ?? true,
    spellCheckConfiguration: config.spellCheckConfiguration,
    magnifierConfiguration: config.magnifierConfiguration,
    hintLocales: config.hintLocales,
  );
}

Iterable<String>? _parseAutofillHints(Object? value) {
  if (value is Iterable) {
    return value.map((entry) => entry.toString()).toList();
  }
  if (value is String) {
    final parts = value.split(',');
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
  return null;
}

EdgeInsets? _edgeInsetsAsInsets(Object? value) {
  final resolved = parseEdgeInsetsGeometry(value);
  if (resolved == null) {
    return null;
  }
  if (resolved is EdgeInsets) {
    return resolved;
  }
  return resolved.resolve(TextDirection.ltr);
}

List<Locale>? _parseLocales(Object? value) {
  if (value is List<Locale>) {
    return value;
  }
  if (value is Iterable) {
    final locales = <Locale>[];
    for (final entry in value) {
      final locale = parseLocale(entry);
      if (locale != null) {
        locales.add(locale);
      }
    }
    return locales.isEmpty ? null : locales;
  }
  if (value is String) {
    final parts = value.split(',');
    final locales = <Locale>[];
    for (final part in parts) {
      final locale = parseLocale(part.trim());
      if (locale != null) {
        locales.add(locale);
      }
    }
    return locales.isEmpty ? null : locales;
  }
  return null;
}
