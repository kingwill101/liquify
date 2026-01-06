// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class TooltipTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  TooltipTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildTooltip(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildTooltip(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('tooltip').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endtooltip').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'tooltip',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _TooltipConfig _parseConfig(Evaluator evaluator) {
    final config = _TooltipConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'message':
          config.message = value?.toString();
          break;
        case 'padding':
          config.padding = parseEdgeInsetsGeometry(value);
          break;
        case 'margin':
          config.margin = parseEdgeInsetsGeometry(value);
          break;
        case 'height':
          config.height = toDouble(value);
          break;
        case 'verticalOffset':
          config.verticalOffset = toDouble(value);
          break;
        case 'preferBelow':
          config.preferBelow = toBool(value);
          break;
        case 'waitDuration':
          config.waitDuration = parseDuration(value);
          break;
        case 'showDuration':
          config.showDuration = parseDuration(value);
          break;
        case 'triggerMode':
          config.triggerMode = parseTooltipTriggerMode(value);
          break;
        case 'textStyle':
          config.textStyle = parseTextStyle(value);
          break;
        case 'decoration':
          config.decoration = parseDecoration(evaluator, value);
          break;
        case 'enableFeedback':
          config.enableFeedback = toBool(value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          break;
        default:
          handleUnknownArg('tooltip', name);
          break;
      }
    }
    return config;
  }
}

class _TooltipConfig {
  String? message;
  EdgeInsetsGeometry? padding;
  EdgeInsetsGeometry? margin;
  double? height;
  double? verticalOffset;
  bool? preferBelow;
  Duration? waitDuration;
  Duration? showDuration;
  TooltipTriggerMode? triggerMode;
  TextStyle? textStyle;
  Decoration? decoration;
  bool? enableFeedback;
  Widget? child;
}

Widget _buildTooltip(_TooltipConfig config, List<Widget> children) {
  final child =
      config.child ??
      (children.isEmpty ? const SizedBox.shrink() : wrapChildren(children));
  return Tooltip(
    message: config.message ?? '',
    padding: config.padding,
    margin: config.margin,
    height: config.height,
    verticalOffset: config.verticalOffset,
    preferBelow: config.preferBelow,
    waitDuration: config.waitDuration,
    showDuration: config.showDuration,
    triggerMode: config.triggerMode,
    textStyle: config.textStyle,
    decoration: config.decoration,
    enableFeedback: config.enableFeedback,
    child: child,
  );
}
