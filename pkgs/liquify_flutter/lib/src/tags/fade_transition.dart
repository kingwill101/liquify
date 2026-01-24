import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FadeTransitionTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  FadeTransitionTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildFadeTransition(evaluator.context, config, children));
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
      buffer.write(_buildFadeTransition(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('fade_transition').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag =
        tagStart() & string('endfade_transition').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'fade_transition',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FadeTransitionConfig _parseConfig(Evaluator evaluator) {
    final config = _FadeTransitionConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'opacity':
          config.opacity = _parseOpacity(value);
          break;
        case 'alwaysIncludeSemantics':
          config.alwaysIncludeSemantics = toBool(value);
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('fade_transition', name);
          break;
      }
    }
    return config;
  }
}

class _FadeTransitionConfig {
  Animation<double>? opacity;
  bool? alwaysIncludeSemantics;
  final Map<String, Object?> namedValues = {};
}

Animation<double>? _parseOpacity(Object? value) {
  if (value is Animation<double>) {
    return value;
  }
  final numeric = toDouble(value);
  if (numeric != null) {
    return AlwaysStoppedAnimation(numeric);
  }
  return null;
}

Widget _buildFadeTransition(
  Environment environment,
  _FadeTransitionConfig config,
  List<Widget> children,
) {
  if (config.opacity == null) {
    throw Exception('fade_transition tag requires "opacity"');
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

  return FadeTransition(
    opacity: config.opacity!,
    alwaysIncludeSemantics: config.alwaysIncludeSemantics ?? false,
    child: child,
  );
}
