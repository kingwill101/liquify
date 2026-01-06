import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class BaselineTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  BaselineTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final child = _captureChildSync(evaluator);
    buffer.write(_buildBaseline(config, child));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final child = await _captureChildAsync(evaluator);
    buffer.write(_buildBaseline(config, child));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('baseline').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endbaseline').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'baseline',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _BaselineConfig _parseConfig(Evaluator evaluator) {
    final config = _BaselineConfig();
    final namedValues = <String, Object?>{};

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'baseline':
          config.baseline = toDouble(value);
          break;
        case 'baselineType':
          config.baselineType = parseTextBaseline(value);
          break;
        case 'child':
          namedValues[name] = value;
          break;
        default:
          handleUnknownArg('baseline', name);
          break;
      }
    }

    config.child = resolvePropertyValue<Widget?>(
      environment: evaluator.context,
      namedArgs: namedValues,
      name: 'child',
      parser: (value) => value is Widget ? value : null,
    );

    if (config.baseline == null) {
      throw Exception('baseline tag requires "baseline"');
    }
    if (config.baselineType == null) {
      throw Exception('baseline tag requires "baselineType"');
    }

    return config;
  }

  Widget _captureChildSync(Evaluator evaluator) {
    if (body.isEmpty) {
      return configChildOrEmpty(null);
    }
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    final captured = evaluator.popBufferValue();
    return configChildOrEmpty(captured);
  }

  Future<Widget> _captureChildAsync(Evaluator evaluator) async {
    if (body.isEmpty) {
      return configChildOrEmpty(null);
    }
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    final captured = evaluator.popBufferValue();
    return configChildOrEmpty(captured);
  }

  Widget configChildOrEmpty(Object? captured) {
    if (captured == null) {
      return const SizedBox.shrink();
    }
    final children = WidgetTagBase.asWidgets(captured);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.first;
    }
    return wrapChildren(children);
  }
}

class _BaselineConfig {
  double? baseline;
  TextBaseline? baselineType;
  Widget? child;
}

Widget _buildBaseline(_BaselineConfig config, Widget child) {
  final resolvedChild = config.child ?? child;
  return Baseline(
    baseline: config.baseline ?? 0,
    baselineType: config.baselineType ?? TextBaseline.alphabetic,
    child: resolvedChild,
  );
}
