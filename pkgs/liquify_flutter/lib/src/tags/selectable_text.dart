import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class SelectableTextTag extends WidgetTagBase with AsyncTag {
  SelectableTextTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    _buildSelectableText(evaluator, buffer);
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    _buildSelectableText(evaluator, buffer);
  }

  void _buildSelectableText(Evaluator evaluator, Buffer buffer) {
    dynamic textValue;
    TextSpan? textSpan;
    double? size;
    Color? color;
    FontWeight? weight;
    FontStyle? fontStyle;
    TextAlign? align;
    TextStyle? style;
    StrutStyle? strutStyle;
    TextDirection? textDirection;
    bool? showCursor;
    bool? enableInteractiveSelection;
    Color? selectionColor;
    Color? cursorColor;
    double? cursorWidth;
    double? cursorHeight;
    Radius? cursorRadius;
    int? maxLines;
    int? minLines;
    String? semanticsLabel;
    TextWidthBasis? textWidthBasis;
    TextHeightBehavior? textHeightBehavior;
    final namedValues = <String, Object?>{};

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'data':
        case 'text':
        case 'value':
          textValue = evaluator.evaluate(arg.value);
          break;
        case 'span':
        case 'textSpan':
          final value = evaluator.evaluate(arg.value);
          if (value is TextSpan) {
            textSpan = value;
          }
          break;
        case 'fontSize':
        case 'size':
          size = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'color':
          namedValues[name] = evaluator.evaluate(arg.value);
          break;
        case 'fontWeight':
        case 'weight':
          weight = parseFontWeight(evaluator.evaluate(arg.value));
          break;
        case 'fontStyle':
          fontStyle = parseFontStyle(evaluator.evaluate(arg.value));
          break;
        case 'textAlign':
          align = parseTextAlign(evaluator.evaluate(arg.value));
          break;
        case 'style':
          final value = evaluator.evaluate(arg.value);
          if (value is TextStyle) {
            style = value;
          }
          break;
        case 'strutStyle':
          final value = evaluator.evaluate(arg.value);
          if (value is StrutStyle) {
            strutStyle = value;
          }
          break;
        case 'textDirection':
          textDirection = parseTextDirection(evaluator.evaluate(arg.value));
          break;
        case 'showCursor':
          showCursor = toBool(evaluator.evaluate(arg.value));
          break;
        case 'enableInteractiveSelection':
          enableInteractiveSelection = toBool(evaluator.evaluate(arg.value));
          break;
        case 'selectionColor':
          selectionColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'cursorColor':
          cursorColor = parseColor(evaluator.evaluate(arg.value));
          break;
        case 'cursorWidth':
          cursorWidth = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'cursorHeight':
          cursorHeight = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'cursorRadius':
          final value = evaluator.evaluate(arg.value);
          if (value is Radius) {
            cursorRadius = value;
          }
          break;
        case 'maxLines':
          maxLines = toInt(evaluator.evaluate(arg.value));
          break;
        case 'minLines':
          minLines = toInt(evaluator.evaluate(arg.value));
          break;
        case 'semanticsLabel':
          semanticsLabel = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'textWidthBasis':
          textWidthBasis = parseTextWidthBasis(evaluator.evaluate(arg.value));
          break;
        case 'textHeightBehavior':
          textHeightBehavior =
              parseTextHeightBehavior(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('selectable_text', name);
          break;
      }
    }

    color = resolvePropertyValue<Color?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'color',
      parser: parseColor,
    );

    textValue ??= _evaluatePositionalValue(evaluator, content);
    final rendered = textValue == null
        ? ''
        : applyFilters(textValue, evaluator).toString();

    final resolvedStyle = style == null
        ? (size != null || color != null || weight != null || fontStyle != null)
            ? TextStyle(
                fontSize: size,
                color: color,
                fontWeight: weight,
                fontStyle: fontStyle,
              )
            : null
        : style.copyWith(
            fontSize: size ?? style.fontSize,
            color: color ?? style.color,
            fontWeight: weight ?? style.fontWeight,
            fontStyle: fontStyle ?? style.fontStyle,
          );

    if (textSpan != null) {
      buffer.write(
        SelectableText.rich(
          textSpan,
          style: resolvedStyle,
          strutStyle: strutStyle,
          textAlign: align,
          textDirection: textDirection,
          showCursor: showCursor ?? false,
          enableInteractiveSelection: enableInteractiveSelection ?? true,
          selectionColor: selectionColor,
          cursorColor: cursorColor,
          cursorWidth: cursorWidth ?? 2.0,
          cursorHeight: cursorHeight,
          cursorRadius: cursorRadius,
          maxLines: maxLines,
          minLines: minLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        ),
      );
      return;
    }

    buffer.write(
      SelectableText(
        rendered,
        style: resolvedStyle,
        strutStyle: strutStyle,
        textAlign: align,
        textDirection: textDirection,
        showCursor: showCursor ?? false,
        enableInteractiveSelection: enableInteractiveSelection ?? true,
        selectionColor: selectionColor,
        cursorColor: cursorColor,
        cursorWidth: cursorWidth ?? 2.0,
        cursorHeight: cursorHeight,
        cursorRadius: cursorRadius,
        maxLines: maxLines,
        minLines: minLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      ),
    );
  }
}

dynamic _evaluatePositionalValue(
  Evaluator evaluator,
  List<ASTNode> content,
) {
  final positional = content.where((node) => node is! NamedArgument).toList();
  if (positional.isEmpty) {
    return null;
  }
  if (positional.length == 1) {
    return evaluator.evaluate(positional.first);
  }
  final buffer = StringBuffer();
  for (final node in positional) {
    buffer.write(evaluator.evaluate(node));
  }
  return buffer.toString();
}
