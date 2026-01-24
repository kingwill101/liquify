import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class HeroTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  HeroTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = WidgetTagBase.asWidgets(captured);
      buffer.write(_buildHero(evaluator.context, config, children));
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
      buffer.write(_buildHero(evaluator.context, config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('hero').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endhero').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'hero',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _HeroConfig _parseConfig(Evaluator evaluator) {
    final config = _HeroConfig();
    String? id;
    String? keyValue;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'tag':
          config.tag = value;
          break;
        case 'transitionOnUserGestures':
          config.transitionOnUserGestures = toBool(value);
          break;
        case 'createRectTween':
          if (value is CreateRectTween) {
            config.createRectTween = value;
          }
          break;
        case 'flightShuttleBuilder':
          if (value is HeroFlightShuttleBuilder) {
            config.flightShuttleBuilder = value;
          }
          break;
        case 'placeholderBuilder':
          if (value is HeroPlaceholderBuilder) {
            config.placeholderBuilder = value;
          }
          break;
        case 'key':
          if (value is Key) {
            config.key = value;
          } else {
            keyValue = value?.toString();
          }
          break;
        case 'id':
          id = value?.toString();
          break;
        case 'child':
          config.namedValues[name] = value;
          break;
        default:
          handleUnknownArg('hero', name);
          break;
      }
    }
    if (config.key == null && (id != null || keyValue != null)) {
      final ids = resolveIds(evaluator, 'hero', id: id, key: keyValue);
      config.key = ids.key;
    }
    return config;
  }
}

class _HeroConfig {
  Object? tag;
  bool? transitionOnUserGestures;
  CreateRectTween? createRectTween;
  HeroFlightShuttleBuilder? flightShuttleBuilder;
  HeroPlaceholderBuilder? placeholderBuilder;
  Key? key;
  final Map<String, Object?> namedValues = {};
}

Widget _buildHero(
  Environment environment,
  _HeroConfig config,
  List<Widget> children,
) {
  if (config.tag == null) {
    throw Exception('hero tag requires "tag"');
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

  return Hero(
    key: config.key,
    tag: config.tag!,
    createRectTween: config.createRectTween,
    flightShuttleBuilder: config.flightShuttleBuilder,
    placeholderBuilder: config.placeholderBuilder,
    transitionOnUserGestures: config.transitionOnUserGestures ?? false,
    child: child,
  );
}
