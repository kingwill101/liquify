// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ProgressTag extends WidgetTagBase with AsyncTag {
  ProgressTag(this.tagName, this.defaultType, super.content, super.filters);

  final String tagName;
  final String? defaultType;

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    buffer.write(_buildProgress(config));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    buffer.write(_buildProgress(config));
  }

  _ProgressConfig _parseConfig(Evaluator evaluator) {
    final config = _ProgressConfig();
    final namedValues = <String, Object?>{};
    config.type = defaultType;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'type':
          config.type = value?.toString();
          break;
        case 'adaptive':
          config.adaptive = toBool(value);
          break;
        case 'value':
          config.value = toDouble(value);
          break;
        case 'color':
          namedValues[name] = value;
          break;
        case 'backgroundColor':
          namedValues[name] = value;
          break;
        case 'valueColor':
          namedValues[name] = value;
          break;
        case 'minHeight':
          config.minHeight = toDouble(value);
          break;
        case 'borderRadius':
          namedValues[name] = value;
          break;
        case 'stopIndicatorColor':
          namedValues[name] = value;
          break;
        case 'stopIndicatorRadius':
          config.stopIndicatorRadius = toDouble(value);
          break;
        case 'trackGap':
          config.trackGap = toDouble(value);
          break;
        case 'semanticsLabel':
          config.semanticsLabel = value?.toString();
          break;
        case 'semanticsValue':
          config.semanticsValue = value?.toString();
          break;
        case 'year2023':
          config.year2023 = toBool(value);
          break;
        case 'strokeWidth':
          config.strokeWidth = toDouble(value);
          break;
        case 'strokeAlign':
          config.strokeAlign = parseStrokeAlign(value);
          break;
        case 'strokeCap':
          config.strokeCap = parseStrokeCap(value);
          break;
        case 'size':
          config.size = toDouble(value);
          break;
        case 'constraints':
          namedValues[name] = value;
          break;
        case 'padding':
          namedValues[name] = value;
          break;
        case 'controller':
          if (value is AnimationController) {
            config.controller = value;
          }
          break;
        default:
          handleUnknownArg(tagName, name);
          break;
      }
    }
    config.color =
        resolvePropertyValue<Color?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'color',
          parser: parseColor,
        ) ??
        config.color;
    config.backgroundColor =
        resolvePropertyValue<Color?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'backgroundColor',
          parser: parseColor,
        ) ??
        config.backgroundColor;
    config.valueColor =
        resolvePropertyValue<Animation<Color?>?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'valueColor',
          parser: parseAnimationOfColor,
        ) ??
        config.valueColor;
    config.borderRadius =
        resolvePropertyValue<BorderRadiusGeometry?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'borderRadius',
          parser: parseBorderRadiusGeometry,
        ) ??
        config.borderRadius;
    config.stopIndicatorColor =
        resolvePropertyValue<Color?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'stopIndicatorColor',
          parser: parseColor,
        ) ??
        config.stopIndicatorColor;
    config.constraints =
        resolvePropertyValue<BoxConstraints?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'constraints',
          parser: parseBoxConstraints,
        ) ??
        config.constraints;
    config.padding =
        resolvePropertyValue<EdgeInsetsGeometry?>(
          environment: evaluator.context,
          namedArgs: namedValues,
          name: 'padding',
          parser: parseEdgeInsetsGeometry,
        ) ??
        config.padding;
    return config;
  }
}

class _ProgressConfig {
  String? type;
  bool? adaptive;
  double? value;
  Color? color;
  Color? backgroundColor;
  Animation<Color?>? valueColor;
  String? semanticsLabel;
  String? semanticsValue;
  double? minHeight;
  BorderRadiusGeometry? borderRadius;
  Color? stopIndicatorColor;
  double? stopIndicatorRadius;
  double? trackGap;
  bool? year2023;
  double? strokeWidth;
  double? strokeAlign;
  StrokeCap? strokeCap;
  BoxConstraints? constraints;
  EdgeInsetsGeometry? padding;
  double? size;
  AnimationController? controller;
}

Widget _buildProgress(_ProgressConfig config) {
  final normalized = config.type?.toLowerCase().trim() ?? 'linear';
  if (normalized == 'circular' ||
      normalized == 'circle' ||
      normalized == 'adaptive') {
    final adaptive = config.adaptive ?? normalized == 'adaptive';
    final constraints =
        config.constraints ??
        (config.size == null
            ? null
            : BoxConstraints.tightFor(width: config.size, height: config.size));
    final indicator = adaptive
        ? CircularProgressIndicator.adaptive(
            value: config.value,
            backgroundColor: config.backgroundColor,
            valueColor: config.valueColor,
            strokeWidth: config.strokeWidth,
            strokeAlign: config.strokeAlign,
            strokeCap: config.strokeCap,
            semanticsLabel: config.semanticsLabel,
            semanticsValue: config.semanticsValue,
            constraints: constraints,
            trackGap: config.trackGap,
            year2023: config.year2023,
            padding: config.padding,
            controller: config.controller,
          )
        : CircularProgressIndicator(
            value: config.value,
            color: config.color,
            backgroundColor: config.backgroundColor,
            valueColor: config.valueColor,
            strokeWidth: config.strokeWidth,
            strokeAlign: config.strokeAlign,
            strokeCap: config.strokeCap,
            semanticsLabel: config.semanticsLabel,
            semanticsValue: config.semanticsValue,
            constraints: constraints,
            trackGap: config.trackGap,
            year2023: config.year2023,
            padding: config.padding,
            controller: config.controller,
          );
    return indicator;
  }
  return LinearProgressIndicator(
    value: config.value,
    color: config.color,
    backgroundColor: config.backgroundColor,
    valueColor: config.valueColor,
    minHeight: config.minHeight,
    semanticsLabel: config.semanticsLabel,
    semanticsValue: config.semanticsValue,
    borderRadius: config.borderRadius,
    stopIndicatorColor: config.stopIndicatorColor,
    stopIndicatorRadius: config.stopIndicatorRadius,
    trackGap: config.trackGap,
    year2023: config.year2023,
    controller: config.controller,
  );
}
