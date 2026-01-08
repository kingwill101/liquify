import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class WrapTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  WrapTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildWrap(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildWrap(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('wrap').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endwrap').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'wrap',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _WrapConfig _parseConfig(Evaluator evaluator) {
    final config = _WrapConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'alignment':
          config.alignment = parseWrapAlignment(value);
          break;
        case 'crossAxisAlignment':
          config.crossAxisAlignment = parseWrapCrossAlignment(value);
          break;
        case 'runAlignment':
          config.runAlignment = parseWrapAlignment(value);
          break;
        case 'spacing':
        case 'gap':
          config.spacing = toDouble(value);
          break;
        case 'runSpacing':
        case 'runGap':
          config.runSpacing = toDouble(value);
          break;
        case 'direction':
        case 'axis':
          config.direction = parseAxis(value);
          break;
        case 'horizontal':
          if (toBool(value) == true) {
            config.direction = Axis.horizontal;
          }
          break;
        case 'vertical':
          if (toBool(value) == true) {
            config.direction = Axis.vertical;
          }
          break;
        case 'textDirection':
          config.textDirection = parseTextDirection(value);
          break;
        case 'verticalDirection':
          config.verticalDirection = parseVerticalDirection(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        default:
          handleUnknownArg('wrap', name);
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

class _WrapConfig {
  WrapAlignment? alignment;
  WrapAlignment? runAlignment;
  WrapCrossAlignment? crossAxisAlignment;
  double? spacing;
  double? runSpacing;
  Axis? direction;
  TextDirection? textDirection;
  VerticalDirection? verticalDirection;
  Clip? clipBehavior;
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}

Widget _buildWrap(_WrapConfig config, List<Widget> children) {
  final axis = switch (config.direction) {
    Axis.vertical => Axis.vertical,
    _ => Axis.horizontal,
  };
  return Wrap(
    direction: axis,
    alignment: config.alignment ?? WrapAlignment.start,
    runAlignment: config.runAlignment ?? WrapAlignment.start,
    crossAxisAlignment: config.crossAxisAlignment ?? WrapCrossAlignment.start,
    spacing: config.spacing ?? 0,
    runSpacing: config.runSpacing ?? 0,
    textDirection: config.textDirection,
    verticalDirection: config.verticalDirection ?? VerticalDirection.down,
    clipBehavior: switch (config.clipBehavior) {
      null => Clip.none,
      final clip => clip,
    },
    children: children,
  );
}
