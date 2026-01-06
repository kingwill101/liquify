import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FlexibleTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  FlexibleTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildFlexible(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildFlexible(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('flexible').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endflexible').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'flexible',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FlexibleConfig _parseConfig(Evaluator evaluator) {
    final config = _FlexibleConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'flex':
          config.flex = toInt(value) ?? 1;
          break;
        case 'fit':
          config.fit = parseFlexFit(value);
          break;
        default:
          handleUnknownArg('flexible', name);
          break;
      }
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

class _FlexibleConfig {
  int flex = 1;
  FlexFit? fit;
}

Widget _buildFlexible(_FlexibleConfig config, List<Widget> children) {
  final child = wrapChildren(children);
  final fit = switch (config.fit) {
    null => FlexFit.loose,
    final resolved => resolved,
  };
  return Flexible(flex: config.flex, fit: fit, child: child);
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
