// ignore_for_file: deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TextTag extends WidgetTagBase with AsyncTag {
  TextTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    dynamic textValue;
    double? size;
    Color? color;
    FontWeight? weight;
    FontStyle? fontStyle;
    TextAlign? align;
    TextStyle? style;
    StrutStyle? strutStyle;
    TextDirection? textDirection;
    Locale? locale;
    bool? softWrap;
    TextOverflow? overflow;
    double? textScaleFactor;
    TextScaler? textScaler;
    int? maxLines;
    String? semanticsLabel;
    String? semanticsIdentifier;
    TextWidthBasis? textWidthBasis;
    TextHeightBehavior? textHeightBehavior;
    Color? selectionColor;
    InlineSpan? textSpan;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'text':
        case 'value':
        case 'data':
          textValue = evaluator.evaluate(arg.value);
          break;
        case 'span':
        case 'textSpan':
          final value = evaluator.evaluate(arg.value);
          if (value is InlineSpan) {
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
        case 'align':
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
        case 'locale':
          locale = parseLocale(evaluator.evaluate(arg.value));
          break;
        case 'softWrap':
          softWrap = toBool(evaluator.evaluate(arg.value));
          break;
        case 'overflow':
          overflow = parseTextOverflow(evaluator.evaluate(arg.value));
          break;
        case 'textScaleFactor':
          textScaleFactor = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'textScaler':
          textScaler = parseTextScaler(evaluator.evaluate(arg.value));
          break;
        case 'maxLines':
          maxLines = toInt(evaluator.evaluate(arg.value));
          break;
        case 'semanticsLabel':
          semanticsLabel = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'semanticsIdentifier':
          semanticsIdentifier = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'textWidthBasis':
          textWidthBasis = parseTextWidthBasis(evaluator.evaluate(arg.value));
          break;
        case 'textHeightBehavior':
          textHeightBehavior = parseTextHeightBehavior(evaluator.evaluate(arg.value));
          break;
        case 'selectionColor':
          selectionColor = parseColor(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('text', name);
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
    if (textScaleFactor != null && textScaler != null) {
      throw Exception('text tag cannot specify both textScaleFactor and textScaler');
    }
    if (textSpan != null) {
      buffer.write(
        Text.rich(
          textSpan,
          style: resolvedStyle,
          strutStyle: strutStyle,
          textAlign: align,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          semanticsIdentifier: semanticsIdentifier,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        ),
      );
      return;
    }
    buffer.write(
      Text(
        rendered,
        style: resolvedStyle,
        strutStyle: strutStyle,
        textAlign: align,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      ),
    );
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    dynamic textValue;
    double? size;
    Color? color;
    FontWeight? weight;
    FontStyle? fontStyle;
    TextAlign? align;
    TextStyle? style;
    StrutStyle? strutStyle;
    TextDirection? textDirection;
    Locale? locale;
    bool? softWrap;
    TextOverflow? overflow;
    double? textScaleFactor;
    TextScaler? textScaler;
    int? maxLines;
    String? semanticsLabel;
    String? semanticsIdentifier;
    TextWidthBasis? textWidthBasis;
    TextHeightBehavior? textHeightBehavior;
    Color? selectionColor;
    InlineSpan? textSpan;
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'text':
        case 'value':
        case 'data':
          textValue = evaluator.evaluate(arg.value);
          break;
        case 'span':
        case 'textSpan':
          final value = evaluator.evaluate(arg.value);
          if (value is InlineSpan) {
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
        case 'align':
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
        case 'locale':
          locale = parseLocale(evaluator.evaluate(arg.value));
          break;
        case 'softWrap':
          softWrap = toBool(evaluator.evaluate(arg.value));
          break;
        case 'overflow':
          overflow = parseTextOverflow(evaluator.evaluate(arg.value));
          break;
        case 'textScaleFactor':
          textScaleFactor = toDouble(evaluator.evaluate(arg.value));
          break;
        case 'textScaler':
          textScaler = parseTextScaler(evaluator.evaluate(arg.value));
          break;
        case 'maxLines':
          maxLines = toInt(evaluator.evaluate(arg.value));
          break;
        case 'semanticsLabel':
          semanticsLabel = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'semanticsIdentifier':
          semanticsIdentifier = evaluator.evaluate(arg.value)?.toString();
          break;
        case 'textWidthBasis':
          textWidthBasis = parseTextWidthBasis(evaluator.evaluate(arg.value));
          break;
        case 'textHeightBehavior':
          textHeightBehavior = parseTextHeightBehavior(evaluator.evaluate(arg.value));
          break;
        case 'selectionColor':
          selectionColor = parseColor(evaluator.evaluate(arg.value));
          break;
        default:
          handleUnknownArg('text', name);
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
        : (await applyFiltersAsync(textValue, evaluator)).toString();
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
    if (textScaleFactor != null && textScaler != null) {
      throw Exception('text tag cannot specify both textScaleFactor and textScaler');
    }
    if (textSpan != null) {
      buffer.write(
        Text.rich(
          textSpan,
          style: resolvedStyle,
          strutStyle: strutStyle,
          textAlign: align,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          semanticsIdentifier: semanticsIdentifier,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        ),
      );
      return;
    }
    buffer.write(
      Text(
        rendered,
        style: resolvedStyle,
        strutStyle: strutStyle,
        textAlign: align,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
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
