import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AnimatedContainerTag extends WidgetTagBase
    with CustomTagParser, AsyncTag {
  AnimatedContainerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildContainer(evaluator, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildContainer(evaluator, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('animated_container').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endanimated_container').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'animated_container',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _AnimatedContainerConfig _parseConfig(Evaluator evaluator) {
    final config = _AnimatedContainerConfig();
    Object? onEndValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'padding':
        case 'margin':
        case 'alignment':
        case 'color':
        case 'decoration':
        case 'foregroundDecoration':
        case 'constraints':
        case 'transform':
        case 'transformAlignment':
        case 'width':
        case 'height':
        case 'child':
          config.namedValues[name] = value;
          break;
        case 'clip':
        case 'clipBehavior':
          config.namedValues['clipBehavior'] = value;
          break;
        case 'duration':
          config.duration = parseDuration(value);
          break;
        case 'curve':
          config.curve = parseCurve(value);
          break;
        case 'onEnd':
          onEndValue = value;
          break;
        default:
          handleUnknownArg('animated_container', name);
          break;
      }
    }
    config.onEnd = resolveActionCallback(evaluator, onEndValue);
    return config;
  }
}

class _AnimatedContainerConfig {
  Duration? duration;
  Curve? curve;
  VoidCallback? onEnd;
  final Map<String, Object?> namedValues = {};
}

Widget _buildContainer(
  Evaluator evaluator,
  _AnimatedContainerConfig config,
  List<Widget> children,
) {
  final environment = evaluator.context;
  if (config.duration == null) {
    throw Exception('animated_container tag requires "duration"');
  }
  final padding = resolvePropertyValue<EdgeInsetsGeometry?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'padding',
    parser: parseEdgeInsetsGeometry,
  );
  final margin = resolvePropertyValue<EdgeInsetsGeometry?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'margin',
    parser: parseEdgeInsetsGeometry,
  );
  final alignment = resolvePropertyValue<AlignmentGeometry?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'alignment',
    parser: parseAlignmentGeometry,
  );
  final color = resolvePropertyValue<Color?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'color',
    parser: parseColor,
  );
  final decoration = resolvePropertyValue<Decoration?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'decoration',
    parser: (value) => parseDecoration(evaluator, value),
  );
  final foregroundDecoration = resolvePropertyValue<Decoration?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'foregroundDecoration',
    parser: (value) => parseDecoration(evaluator, value),
  );
  final constraints = resolvePropertyValue<BoxConstraints?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'constraints',
    parser: (value) => value is BoxConstraints ? value : null,
  );
  final transform = resolvePropertyValue<Matrix4?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'transform',
    parser: (value) => value is Matrix4 ? value : null,
  );
  final transformAlignment = resolvePropertyValue<AlignmentGeometry?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'transformAlignment',
    parser: parseAlignmentGeometry,
  );
  final clipBehavior = resolvePropertyValue<Clip?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'clipBehavior',
    parser: parseClip,
  );
  final width = resolvePropertyValue<double?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'width',
    parser: toDouble,
  );
  final height = resolvePropertyValue<double?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'height',
    parser: toDouble,
  );
  final childOverride = resolvePropertyValue<Widget?>(
    environment: environment,
    namedArgs: config.namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );

  Widget child;
  if (childOverride != null) {
    child = childOverride;
  } else if (children.isEmpty) {
    child = const SizedBox.shrink();
  } else if (children.length == 1) {
    child = children.first;
  } else {
    child = wrapChildren(children);
  }

  return AnimatedContainer(
    alignment: alignment,
    padding: padding,
    color: color,
    decoration: decoration,
    foregroundDecoration: foregroundDecoration,
    width: width,
    height: height,
    constraints: constraints,
    margin: margin,
    transform: transform,
    transformAlignment: transformAlignment,
    clipBehavior: clipBehavior ?? Clip.none,
    duration: config.duration!,
    curve: config.curve ?? Curves.linear,
    onEnd: config.onEnd,
    child: child,
  );
}
