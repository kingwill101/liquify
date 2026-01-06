import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'property_resolver.dart';
import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ContainerTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ContainerTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final namedArgs = _parseNamedArgs(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      evaluator.evaluateNodes(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      buffer.write(_buildContainer(evaluator, namedArgs, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final namedArgs = _parseNamedArgs(evaluator);
    final scope = pushPropertyScope(evaluator.context);
    evaluator.startBlockCapture();
    try {
      await evaluator.evaluateNodesAsync(body);
      final captured = evaluator.popBufferValue();
      final children = _asWidgets(captured);
      buffer.write(_buildContainer(evaluator, namedArgs, children));
    } finally {
      popPropertyScope(evaluator.context, scope);
    }
  }

  @override
  Parser parser() {
    final start =
        tagStart() &
        string('container').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endcontainer').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent = content
          .where((node) => node is! Filter)
          .toList();
      return Tag(
        'container',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  Map<String, Object?> _parseNamedArgs(Evaluator evaluator) {
    final values = <String, Object?>{};
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'padding':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'margin':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'alignment':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'color':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'decoration':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'foregroundDecoration':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'constraints':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'transform':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'transformAlignment':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'clip':
        case 'clipBehavior':
          values['clipBehavior'] = evaluator.evaluate(arg.value);
          break;
        case 'width':
          values[name] = evaluator.evaluate(arg.value);
          break;
        case 'height':
          values[name] = evaluator.evaluate(arg.value);
          break;
        default:
          handleUnknownArg('container', name);
          break;
      }
    }
    return values;
  }

  Widget _buildContainer(
    Evaluator evaluator,
    Map<String, Object?> namedArgs,
    List<Widget> children,
  ) {
    final environment = evaluator.context;
    final padding = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'padding',
      parser: parseEdgeInsetsGeometry,
    );
    final margin = resolvePropertyValue<EdgeInsetsGeometry?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'margin',
      parser: parseEdgeInsetsGeometry,
    );
    final alignment = resolvePropertyValue<AlignmentGeometry?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'alignment',
      parser: parseAlignmentGeometry,
    );
    final color = resolvePropertyValue<Color?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'color',
      parser: parseColor,
    );
    final decoration = resolvePropertyValue<Decoration?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'decoration',
      parser: (value) => parseDecoration(evaluator, value),
    );
    final foregroundDecoration = resolvePropertyValue<Decoration?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'foregroundDecoration',
      parser: (value) => parseDecoration(evaluator, value),
    );
    final constraints = resolvePropertyValue<BoxConstraints?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'constraints',
      parser: (value) => value is BoxConstraints ? value : null,
    );
    final transform = resolvePropertyValue<Matrix4?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'transform',
      parser: (value) => value is Matrix4 ? value : null,
    );
    final transformAlignment = resolvePropertyValue<AlignmentGeometry?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'transformAlignment',
      parser: parseAlignmentGeometry,
    );
    final clipBehavior = resolvePropertyValue<Clip?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'clipBehavior',
      parser: parseClip,
    );
    final width = resolvePropertyValue<double?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'width',
      parser: toDouble,
    );
    final height = resolvePropertyValue<double?>(
      environment: environment,
      namedArgs: namedArgs,
      name: 'height',
      parser: toDouble,
    );
    final childOverride = resolvePropertyValue<Widget?>(
      environment: environment,
      namedArgs: namedArgs,
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

    return Container(
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior ?? Clip.none,
      child: child,
    );
  }
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
