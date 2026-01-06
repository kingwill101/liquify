import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class IndexedStackTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  IndexedStackTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = captureChildrenSync(evaluator);
    buffer.write(_buildIndexedStack(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await captureChildrenAsync(evaluator);
    buffer.write(_buildIndexedStack(config, children));
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('indexed_stack').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endindexed_stack').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'indexed_stack',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _IndexedStackConfig _parseConfig(Evaluator evaluator) {
    final config = _IndexedStackConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'alignment':
          config.alignment = parseAlignmentGeometry(value);
          break;
        case 'textDirection':
          config.textDirection = parseTextDirection(value);
          break;
        case 'sizing':
          config.sizing = parseStackFit(value);
          break;
        case 'index':
          config.index = toInt(value);
          break;
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        default:
          handleUnknownArg('indexed_stack', name);
          break;
      }
    }
    return config;
  }
}

class _IndexedStackConfig {
  AlignmentGeometry? alignment;
  TextDirection? textDirection;
  StackFit? sizing;
  int? index;
  Clip? clipBehavior;
}

Widget _buildIndexedStack(_IndexedStackConfig config, List<Widget> children) {
  if (children.isEmpty) {
    return const SizedBox.shrink();
  }
  return IndexedStack(
    alignment: config.alignment ?? AlignmentDirectional.topStart,
    textDirection: config.textDirection,
    sizing: config.sizing ?? StackFit.loose,
    index: config.index ?? 0,
    clipBehavior: config.clipBehavior ?? Clip.hardEdge,
    children: children,
  );
}
