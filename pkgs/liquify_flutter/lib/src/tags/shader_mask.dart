import 'package:flutter/material.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ShaderMaskTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ShaderMaskTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildMask(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildMask(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('shader_mask').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endshader_mask').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'shader_mask',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ShaderMaskConfig _parseConfig(Evaluator evaluator) {
    final config = _ShaderMaskConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'blendMode':
          config.blendMode = parseBlendMode(value);
          break;
        case 'shaderCallback':
          if (value is ShaderCallback) {
            config.shaderCallback = value;
          }
          break;
        case 'gradient':
          config.gradient = _parseGradient(value);
          break;
        case 'child':
          if (value is Widget) {
            config.child = value;
          }
          break;
        default:
          handleUnknownArg('shader_mask', name);
          break;
      }
    }
    return config;
  }
}

class _ShaderMaskConfig {
  BlendMode? blendMode;
  ShaderCallback? shaderCallback;
  Gradient? gradient;
  Widget? child;
}

Widget _buildMask(_ShaderMaskConfig config, List<Widget> children) {
  final child = config.child ??
      (children.isEmpty
          ? const SizedBox.shrink()
          : children.length == 1
              ? children.first
              : wrapChildren(children));

  final shaderCallback = config.shaderCallback ??
      (Rect bounds) {
        final gradient = config.gradient ??
            const LinearGradient(
              colors: [Colors.white, Colors.white],
            );
        return gradient.createShader(bounds);
      };

  return ShaderMask(
    blendMode: config.blendMode ?? BlendMode.srcIn,
    shaderCallback: shaderCallback,
    child: child,
  );
}

Gradient? _parseGradient(Object? value) {
  if (value is Gradient) {
    return value;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final colorsRaw = map['colors'];
    if (colorsRaw is Iterable) {
      final colors = <Color>[];
      for (final entry in colorsRaw) {
        final color = parseColor(entry);
        if (color != null) {
          colors.add(color);
        }
      }
      if (colors.isEmpty) {
        return null;
      }
      final stopsRaw = map['stops'];
      final stops = stopsRaw is Iterable
          ? stopsRaw.map((entry) => toDouble(entry) ?? 0).toList()
          : null;
      final begin = parseAlignmentGeometry(map['begin']) ?? Alignment.topLeft;
      final end = parseAlignmentGeometry(map['end']) ?? Alignment.bottomRight;
      return LinearGradient(colors: colors, stops: stops, begin: begin, end: end);
    }
  }
  return null;
}
