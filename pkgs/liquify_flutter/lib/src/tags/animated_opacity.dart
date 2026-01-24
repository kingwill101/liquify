import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AnimatedOpacityTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  AnimatedOpacityTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildOpacity(evaluator.context, config, children));
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
      buffer.write(_buildOpacity(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('animated_opacity').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endanimated_opacity').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'animated_opacity',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _AnimatedOpacityConfig _parseConfig(Evaluator evaluator) {
    final config = _AnimatedOpacityConfig();
    Object? onEndValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'opacity':
          config.opacity = toDouble(value);
          break;
        case 'duration':
          config.duration = parseDuration(value);
          break;
        case 'curve':
          config.curve = parseCurve(value);
          break;
        case 'alwaysIncludeSemantics':
          config.alwaysIncludeSemantics = toBool(value);
          break;
        case 'onEnd':
          onEndValue = value;
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('animated_opacity', name);
          break;
      }
    }
    config.onEnd = resolveActionCallback(evaluator, onEndValue);
    return config;
  }
}

class _AnimatedOpacityConfig {
  double? opacity;
  Duration? duration;
  Curve? curve;
  bool? alwaysIncludeSemantics;
  VoidCallback? onEnd;
  final Map<String, Object?> namedValues = {};
}

Widget _buildOpacity(
  Environment environment,
  _AnimatedOpacityConfig config,
  List<Widget> children,
) {
  if (config.opacity == null) {
    throw Exception('animated_opacity tag requires "opacity"');
  }
  if (config.duration == null) {
    throw Exception('animated_opacity tag requires "duration"');
  }
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

  return AnimatedOpacity(
    opacity: config.opacity!,
    duration: config.duration!,
    curve: config.curve ?? Curves.linear,
    onEnd: config.onEnd,
    alwaysIncludeSemantics: config.alwaysIncludeSemantics ?? false,
    child: child,
  );
}
