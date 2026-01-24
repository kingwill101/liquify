import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class OffstageTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  OffstageTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildOffstage(evaluator, namedValues, config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildOffstage(evaluator, namedValues, config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('offstage').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endoffstage').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'offstage',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _OffstageConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _OffstageConfig();
    Object? childValue;

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'offstage':
          config.offstage = toBool(value);
          break;
        case 'child':
          childValue = value;
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('offstage', name);
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

    return config;
  }
}

class _OffstageConfig {
  bool? offstage;
  Widget? child;
}

Widget _buildOffstage(
  Evaluator evaluator,
  Map<String, Object?> namedValues,
  _OffstageConfig config,
  List<Widget> children,
) {
  final resolvedChild = resolvePropertyValue<Widget?>(
    environment: evaluator.context,
    namedArgs: namedValues,
    name: 'child',
    parser: (value) => value is Widget ? value : null,
  );
  final child = resolvedChild ?? config.child ?? wrapChildren(children);

  return Offstage(
    offstage: config.offstage ?? true,
    child: child,
  );
}
