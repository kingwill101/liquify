import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';
import 'package:media_break_points/media_break_points.dart';
import 'widget_tag_base.dart';

class BreakpointTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  BreakpointTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    if (!_matches(evaluator)) {
      return null;
    }
    evaluator.startBlockCapture();
    evaluator.evaluateNodes(body);
    buffer.write(evaluator.popBufferValue());
    return null;
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    if (!_matches(evaluator)) {
      return null;
    }
    evaluator.startBlockCapture();
    await evaluator.evaluateNodesAsync(body);
    buffer.write(evaluator.popBufferValue());
    return null;
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('breakpoint').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endbreakpoint').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'breakpoint',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  bool _matches(Evaluator evaluator) {
    final context = evaluator.context.getRegister('_liquify_flutter_context');
    if (context is! BuildContext) {
      throw Exception(
        'breakpoint tag requires a BuildContext. Set environment register '
        '"_liquify_flutter_context" before rendering.',
      );
    }

    final current = breakpoint(context);
    final allowed = <BreakPoint>{};
    final excluded = <BreakPoint>{};
    BreakPoint? min;
    BreakPoint? max;
    var hasCondition = false;

    for (final arg in args) {
      final parsed = _parseBreakpoint(arg.name);
      if (parsed == null) {
        handleUnknownArg('breakpoint', arg.name);
        continue;
      }
      allowed.add(parsed);
      hasCondition = true;
    }

    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      switch (name) {
        case 'min':
          min = _requireBreakpoint(evaluator.evaluate(arg.value), name);
          hasCondition = true;
          break;
        case 'max':
          max = _requireBreakpoint(evaluator.evaluate(arg.value), name);
          hasCondition = true;
          break;
        case 'only':
          allowed.addAll(_parseBreakpointSet(
            evaluator.evaluate(arg.value),
            name,
          ));
          hasCondition = true;
          break;
        case 'except':
          excluded.addAll(_parseBreakpointSet(
            evaluator.evaluate(arg.value),
            name,
          ));
          hasCondition = true;
          break;
        default:
          handleUnknownArg('breakpoint', name);
          break;
      }
    }

    if (!hasCondition) {
      throw Exception('breakpoint tag expects at least one breakpoint');
    }

    if (excluded.contains(current)) {
      return false;
    }

    if (allowed.isNotEmpty && !allowed.contains(current)) {
      return false;
    }

    final currentOrder = _breakpointOrder[current] ?? 0;
    if (min != null) {
      final minOrder = _breakpointOrder[min] ?? 0;
      if (currentOrder < minOrder) {
        return false;
      }
    }
    if (max != null) {
      final maxOrder = _breakpointOrder[max] ?? 0;
      if (currentOrder > maxOrder) {
        return false;
      }
    }

    return true;
  }
}

const Map<BreakPoint, int> _breakpointOrder = {
  BreakPoint.xs: 0,
  BreakPoint.sm: 1,
  BreakPoint.md: 2,
  BreakPoint.lg: 3,
  BreakPoint.xl: 4,
  BreakPoint.xxl: 5,
};

BreakPoint? _parseBreakpoint(Object? value) {
  if (value is BreakPoint) {
    return value;
  }
  if (value == null) {
    return null;
  }
  final name = value.toString().trim().toLowerCase();
  switch (name) {
    case 'xs':
      return BreakPoint.xs;
    case 'sm':
      return BreakPoint.sm;
    case 'md':
      return BreakPoint.md;
    case 'lg':
      return BreakPoint.lg;
    case 'xl':
      return BreakPoint.xl;
    case 'xxl':
      return BreakPoint.xxl;
  }
  return null;
}

BreakPoint _requireBreakpoint(Object? value, String label) {
  final parsed = _parseBreakpoint(value);
  if (parsed == null) {
    throw Exception('breakpoint tag "$label" expects a breakpoint value');
  }
  return parsed;
}

Set<BreakPoint> _parseBreakpointSet(Object? value, String label) {
  if (value is Iterable) {
    final parsed = value
        .map(_parseBreakpoint)
        .whereType<BreakPoint>()
        .toSet();
    if (parsed.isEmpty) {
      throw Exception('breakpoint tag "$label" expects breakpoint values');
    }
    return parsed;
  }
  final single = _parseBreakpoint(value);
  if (single == null) {
    throw Exception('breakpoint tag "$label" expects breakpoint values');
  }
  return {single};
}
