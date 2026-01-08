import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class VisibilityTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  VisibilityTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildVisibility(evaluator, namedValues, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildVisibility(evaluator, namedValues, config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('visibility').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endvisibility').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'visibility',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _VisibilityConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _VisibilityConfig();
    Object? childValue;
    Object? replacementValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'visible':
          config.visible = toBool(value);
          break;
        case 'replacement':
          replacementValue = value;
          namedValues[name] = value;
          break;
        case 'maintainState':
          config.maintainState = toBool(value);
          break;
        case 'maintainAnimation':
          config.maintainAnimation = toBool(value);
          break;
        case 'maintainSize':
          config.maintainSize = toBool(value);
          break;
        case 'maintainSemantics':
          config.maintainSemantics = toBool(value);
          break;
        case 'maintainInteractivity':
          config.maintainInteractivity = toBool(value);
          break;
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('visibility', name);
          break;
      }
    }

    final resolvedChild = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedChild != null) {
      config.child = resolvedChild;
    } else if (childValue != null) {
      config.child =
          childValue is Widget ? childValue : resolveTextWidget(childValue);
    }

    final resolvedReplacement = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'replacement',
      parser: (value) => value is Widget ? value : null,
    );
    if (resolvedReplacement != null) {
      config.replacement = resolvedReplacement;
    } else if (replacementValue != null) {
      config.replacement = replacementValue is Widget
          ? replacementValue
          : resolveTextWidget(replacementValue);
    }

    return config;
  }
}

class _VisibilityConfig {
  bool? visible;
  Widget? replacement;
  bool? maintainState;
  bool? maintainAnimation;
  bool? maintainSize;
  bool? maintainSemantics;
  bool? maintainInteractivity;
  Widget? child;
}

Widget _buildVisibility(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _VisibilityConfig config,
  List<Widget> children,
) {
  final resolvedChild = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );
  final child = resolvedChild ?? config.child ?? wrapChildren(children);
  final replacement = config.replacement ?? const SizedBox.shrink();

  return Visibility(
    visible: config.visible ?? true,
    replacement: replacement,
    maintainState: config.maintainState ?? false,
    maintainAnimation: config.maintainAnimation ?? false,
    maintainSize: config.maintainSize ?? false,
    maintainSemantics: config.maintainSemantics ?? false,
    maintainInteractivity: config.maintainInteractivity ?? false,
    child: child,
  );
}
