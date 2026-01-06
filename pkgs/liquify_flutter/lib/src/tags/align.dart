import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class AlignTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  AlignTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      config.alignment = resolvePropertyValue<AlignmentGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'alignment',
        parser: parseAlignmentGeometry,
      );
      buffer.write(_buildAlign(config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedValues = <String, Object?>{};
    final config = _parseConfig(evaluator, namedValues);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      config.alignment = resolvePropertyValue<AlignmentGeometry?>(
        environment: evaluator.context,
        namedArgs: namedValues,
        name: 'alignment',
        parser: parseAlignmentGeometry,
      );
      buffer.write(_buildAlign(config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('align').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endalign').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'align',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _AlignConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _AlignConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'alignment':
        case 'value':
          namedValues['alignment'] = value;
          break;
        case 'widthFactor':
          config.widthFactor = toDouble(value);
          break;
        case 'heightFactor':
          config.heightFactor = toDouble(value);
          break;
        default:
          handleUnknownArg('align', name);
          break;
      }
    }
    return config;
  }
}

class CenterTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  CenterTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildCenter(children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildCenter(children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('center').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endcenter').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'center',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
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

class _AlignConfig {
  AlignmentGeometry? alignment;
  double? widthFactor;
  double? heightFactor;
}

Widget _buildAlign(_AlignConfig config, List<Widget> children) {
  final child = wrapChildren(children);
  final alignment = switch (config.alignment) {
    null => Alignment.center,
    final resolved => resolved,
  };
  return Align(
    alignment: alignment,
    widthFactor: config.widthFactor,
    heightFactor: config.heightFactor,
    child: child,
  );
}

Widget _buildCenter(List<Widget> children) {
  final child = wrapChildren(children);
  return Center(child: child);
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
