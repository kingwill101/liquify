import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class FittedBoxTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  FittedBoxTag(super.content, super.filters);

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
      buffer.write(_buildFitted(config, children));
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
      buffer.write(_buildFitted(config, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('fitted_box').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endfitted_box').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'fitted_box',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _FittedConfig _parseConfig(
    Evaluator evaluator,
    Map<String, Object?> namedValues,
  ) {
    final config = _FittedConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'fit':
          config.fit = parseBoxFit(value);
          break;
        case 'alignment':
          namedValues[name] = value;
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        default:
          handleUnknownArg('fitted_box', name);
          break;
      }
    }
    return config;
  }
}

class _FittedConfig {
  BoxFit? fit;
  AlignmentGeometry? alignment;
  Clip? clipBehavior;
}

Widget _buildFitted(_FittedConfig config, List<Widget> children) {
  final child = wrapChildren(children);
  return FittedBox(
    fit: config.fit ?? BoxFit.contain,
    alignment: config.alignment ?? Alignment.center,
    clipBehavior: switch (config.clipBehavior) {
      null => Clip.none,
      final clip => clip,
    },
    child: child,
  );
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
