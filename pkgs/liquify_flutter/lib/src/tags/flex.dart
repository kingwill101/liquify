import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FlexTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  FlexTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildFlex(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildFlex(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('flex').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endflex').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'flex',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FlexConfig _parseConfig(Evaluator evaluator) {
    final config = _FlexConfig();
    final namedValues = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'direction':
        case 'axis':
          config.direction = parseAxis(value);
          break;
        case 'mainAxisAlignment':
          config.mainAxisAlignment = parseMainAxisAlignment(value);
          break;
        case 'mainAxisSize':
          config.mainAxisSize = parseMainAxisSize(value);
          break;
        case 'crossAxisAlignment':
          config.crossAxisAlignment = parseCrossAxisAlignment(value);
          break;
        case 'textDirection':
          config.textDirection = parseTextDirection(value);
          break;
        case 'verticalDirection':
          config.verticalDirection = parseVerticalDirection(value);
          break;
        case 'textBaseline':
          config.textBaseline = parseTextBaseline(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        case 'gap':
        case 'spacing':
          config.spacing = toDouble(value);
          break;
        case 'children':
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('flex', name);
          break;
      }
    }
    final resolvedChildren = resolvePropertyValue<List<Widget>>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'children',
      parser: (value) => WidgetTagBase.asWidgets(value),
    );
    if (resolvedChildren != null && resolvedChildren.isNotEmpty) {
      config.children = resolvedChildren;
    }
    if (config.direction == null) {
      throw Exception('flex tag requires "direction"');
    }
    return config;
  }

  List<Widget> _captureChildrenSync(Evaluator evaluator) {
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    final captured = evaluator.popBufferValue();
    return _asWidgets(captured);
  }

  Future<List<Widget>> _captureChildrenAsync(Evaluator evaluator) async {
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    final captured = evaluator.popBufferValue();
    return _asWidgets(captured);
  }
}

class _FlexConfig {
  Axis? direction;
  MainAxisAlignment? mainAxisAlignment;
  MainAxisSize? mainAxisSize;
  CrossAxisAlignment? crossAxisAlignment;
  TextDirection? textDirection;
  VerticalDirection? verticalDirection;
  TextBaseline? textBaseline;
  Clip? clipBehavior;
  double? spacing;
  List<Widget>? children;
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}

Widget _buildFlex(_FlexConfig config, List<Widget> children) {
  final resolvedChildren = config.children ?? children;
  return Flex(
    direction: config.direction!,
    mainAxisAlignment: config.mainAxisAlignment ?? MainAxisAlignment.start,
    mainAxisSize: config.mainAxisSize ?? MainAxisSize.max,
    crossAxisAlignment: config.crossAxisAlignment ?? CrossAxisAlignment.center,
    textDirection: config.textDirection,
    verticalDirection: config.verticalDirection ?? VerticalDirection.down,
    textBaseline: config.textBaseline,
    clipBehavior: config.clipBehavior ?? Clip.none,
    spacing: config.spacing ?? 0,
    children: resolvedChildren,
  );
}
