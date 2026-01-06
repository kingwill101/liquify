// ignore_for_file: deprecated_member_use
import 'dart:ui' show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TextFormFieldTag extends WidgetTagBase with AsyncTag {
  TextFormFieldTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildTextFormField(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildTextFormField(config));
  }

  _TextFormFieldConfig _parseConfig(Evaluator evaluator) {
    final config = _TextFormFieldConfig();
    Object? actionValue;
    Object? onChangedValue;
    Object? onSubmittedValue;
    Object? onSavedValue;
    Object? validatorValue;
    String? widgetIdValue;
    String? widgetKeyValue;
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
        case 'initialValue':
          config.initialValue = value?.toString();
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
          onChangedValue = value;
          break;
        case 'onEditingComplete':
          config.onEditingComplete = resolveActionCallback(evaluator, value);
          break;
        case 'onFieldSubmitted':
        case 'onSubmitted':
          onSubmittedValue = value;
          break;
        case 'onSaved':
          onSavedValue = value;
          break;
        case 'validator':
          validatorValue = value;
          break;
        case 'action':
          actionValue = value;
          break;
        case 'autovalidateMode':
          config.autovalidateMode = parseAutovalidateMode(value);
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
          if (value is ScrollPhysics) {
            config.scrollPhysics = value;
          }
          break;
        case 'autofillHints':
          if (value is Iterable) {
            config.autofillHints = value.map((entry) => entry.toString());
          }
          break;
        case 'contentInsertionConfiguration':
          if (value is ContentInsertionConfiguration) {
            config.contentInsertionConfiguration = value;
          }
          break;
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
          if (value is EditableTextContextMenuBuilder) {
            config.contextMenuBuilder = value;
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
          if (value is Iterable) {
            final locales = <Locale>[];
            for (final entry in value) {
              if (entry is Locale) {
                locales.add(entry);
              }
            }
            config.hintLocales = locales;
          }
          break;
        case 'id':
          widgetIdValue = value?.toString();
          break;
        case 'key':
          widgetKeyValue = value?.toString();
          break;
        default:
          handleUnknownArg('text_form_field', name);
          break;
      }
    }

    final resolvedId = resolveWidgetId(
      evaluator,
      'text_form_field',
      id: widgetIdValue,
      key: widgetKeyValue,
    );
    final resolvedKeyValue =
        (widgetKeyValue != null && widgetKeyValue.trim().isNotEmpty)
        ? widgetKeyValue.trim()
        : resolvedId;
    config.widgetKey = resolveWidgetKey(resolvedId, widgetKeyValue);
    config.validator = _resolveValidator(validatorValue);
    final actionName = actionValue is String ? actionValue : null;
    final changeActionName = onChangedValue is String
        ? onChangedValue
        : actionName;
    final changeEvent = buildWidgetEvent(
      tag: 'text_form_field',
      id: resolvedId,
      key: resolvedKeyValue,
      action: changeActionName,
      event: 'changed',
      props: {'label': config.label, 'hint': config.hint},
    );
    final changeCallback =
        resolveStringActionCallback(
          evaluator,
          onChangedValue,
          event: changeEvent,
          actionValue: changeActionName,
        ) ??
        resolveStringActionCallback(
          evaluator,
          actionValue,
          event: changeEvent,
          actionValue: changeActionName,
        );
    if (changeCallback != null) {
      config.onChanged = (value) {
        changeEvent['value'] = value;
        changeCallback(value);
      };
    }
    final submitActionName = onSubmittedValue is String
        ? onSubmittedValue
        : actionName;
    final submitEvent = buildWidgetEvent(
      tag: 'text_form_field',
      id: resolvedId,
      key: resolvedKeyValue,
      action: submitActionName,
      event: 'submitted',
      props: {'label': config.label, 'hint': config.hint},
    );
    final submitCallback =
        resolveStringActionCallback(
          evaluator,
          onSubmittedValue,
          event: submitEvent,
          actionValue: submitActionName,
        ) ??
        resolveStringActionCallback(
          evaluator,
          actionValue,
          event: submitEvent,
          actionValue: submitActionName,
        );
    if (submitCallback != null) {
      config.onFieldSubmitted = (value) {
        submitEvent['value'] = value;
        submitCallback(value);
      };
    }
    if (onSavedValue is FormFieldSetter<String>) {
      config.onSaved = onSavedValue;
    } else {
      final savedActionName = onSavedValue is String
          ? onSavedValue
          : actionName;
      final savedEvent = buildWidgetEvent(
        tag: 'text_form_field',
        id: resolvedId,
        key: resolvedKeyValue,
        action: savedActionName,
        event: 'saved',
        props: {'label': config.label, 'hint': config.hint},
      );
      final savedCallback =
          resolveStringActionCallback(
            evaluator,
            onSavedValue,
            event: savedEvent,
            actionValue: savedActionName,
          ) ??
          resolveStringActionCallback(
            evaluator,
            actionValue,
            event: savedEvent,
            actionValue: savedActionName,
          );
      if (savedCallback != null) {
        config.onSaved = (value) {
          savedEvent['value'] = value;
          savedCallback(value ?? '');
        };
      }
    }
    return config;
  }
}

class _TextFormFieldConfig {
  Object? groupId;
  TextEditingController? controller;
  String? initialValue;
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
  ValueChanged<String>? onFieldSubmitted;
  FormFieldSetter<String>? onSaved;
  FormFieldValidator<String>? validator;
  AutovalidateMode? autovalidateMode;
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
  Key? widgetKey;
}

TextFormField _buildTextFormField(_TextFormFieldConfig config) {
  final obscureText = config.obscureText ?? false;
  final readOnly = config.readOnly ?? false;
  final maxLines = config.maxLines ?? 1;
  final keyboardType =
      config.keyboardType ??
      (maxLines == 1 ? TextInputType.text : TextInputType.multiline);
  final smartDashesType =
      config.smartDashesType ??
      (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled);
  final smartQuotesType =
      config.smartQuotesType ??
      (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled);
  final enableInteractiveSelection =
      config.enableInteractiveSelection ?? (!readOnly || !obscureText);
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
  } else if (decoration != null &&
      (config.label != null || config.hint != null)) {
    decoration = decoration.copyWith(
      labelText: config.label,
      hintText: config.hint,
    );
  }

  final resolvedInitialValue = config.controller == null
      ? config.initialValue
      : null;

  if (config.contextMenuBuilderProvided) {
    return TextFormField(
      key: config.widgetKey,
      groupId: config.groupId ?? EditableText,
      controller: config.controller,
      initialValue: resolvedInitialValue,
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
      autocorrect: config.autocorrect ?? true,
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
      onFieldSubmitted: config.onFieldSubmitted,
      onSaved: config.onSaved,
      validator: config.validator,
      autovalidateMode: config.autovalidateMode,
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
      autofillHints: config.autofillHints,
      contentInsertionConfiguration: config.contentInsertionConfiguration,
      clipBehavior: config.clipBehavior ?? Clip.hardEdge,
      restorationId: config.restorationId,
      scribbleEnabled: config.scribbleEnabled ?? true,
      stylusHandwritingEnabled:
          config.stylusHandwritingEnabled ??
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

  return TextFormField(
    key: config.widgetKey,
    groupId: config.groupId ?? EditableText,
    controller: config.controller,
    initialValue: resolvedInitialValue,
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
    autocorrect: config.autocorrect ?? true,
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
    onFieldSubmitted: config.onFieldSubmitted,
    onSaved: config.onSaved,
    validator: config.validator,
    autovalidateMode: config.autovalidateMode,
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
    autofillHints: config.autofillHints,
    contentInsertionConfiguration: config.contentInsertionConfiguration,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    restorationId: config.restorationId,
    scribbleEnabled: config.scribbleEnabled ?? true,
    stylusHandwritingEnabled:
        config.stylusHandwritingEnabled ??
        EditableText.defaultStylusHandwritingEnabled,
    enableIMEPersonalizedLearning: config.enableIMEPersonalizedLearning ?? true,
    canRequestFocus: config.canRequestFocus ?? true,
    spellCheckConfiguration: config.spellCheckConfiguration,
    magnifierConfiguration: config.magnifierConfiguration,
    hintLocales: config.hintLocales,
  );
}

FormFieldValidator<String>? _resolveValidator(Object? value) {
  if (value is FormFieldValidator<String>) {
    return value;
  }
  if (value is String) {
    final message = value;
    if (message.trim().isEmpty) {
      return null;
    }
    return (input) {
      final trimmed = input?.trim() ?? '';
      if (trimmed.isEmpty) {
        return message;
      }
      return null;
    };
  }
  return null;
}

EdgeInsets? _edgeInsetsAsInsets(Object? value) {
  final result = parseEdgeInsetsGeometry(value);
  if (result == null) {
    return null;
  }
  if (result is EdgeInsets) {
    return result;
  }
  return result.resolve(TextDirection.ltr);
}
