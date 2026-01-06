import 'package:flutter/widgets.dart';
import 'package:liquify/parser.dart';

import 'tag_helpers.dart';
import 'widget_tag_base.dart';

class ClipRRectTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ClipRRectTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final config = _parseConfig(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_build(config, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final config = _parseConfig(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_build(config, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('clip_rrect').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endclip_rrect').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'clip_rrect',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  _ClipRRectConfig _parseConfig(Evaluator evaluator) {
    final config = _ClipRRectConfig();
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'borderRadius':
        case 'radius':
          config.borderRadius = parseBorderRadiusGeometry(value);
          break;
        case 'clip':
        case 'clipBehavior':
          config.clipBehavior = parseClip(value);
          break;
        default:
          handleUnknownArg('clip_rrect', name);
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

class ClipOvalTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ClipOvalTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final clip = _parseClipBehavior(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildClipOval(clip, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final clip = _parseClipBehavior(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildClipOval(clip, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('clip_oval').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endclip_oval').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'clip_oval',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  Clip _parseClipBehavior(Evaluator evaluator) {
    Clip? clip;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'clip':
        case 'clipBehavior':
          clip = parseClip(value);
          break;
        default:
          handleUnknownArg('clip_oval', name);
          break;
      }
    }
    return switch (clip) {
      null => Clip.antiAlias,
      final resolved => resolved,
    };
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

class ClipRectTag extends WidgetTagBase with CustomTagParser, AsyncTag {
  ClipRectTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final clip = _parseClipBehavior(evaluator);
    final children = _captureChildrenSync(evaluator);
    buffer.write(_buildClipRect(clip, children));
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final clip = _parseClipBehavior(evaluator);
    final children = await _captureChildrenAsync(evaluator);
    buffer.write(_buildClipRect(clip, children));
  }

  @override
  Parser parser() {
    final start = tagStart() &
        string('clip_rect').trim() &
        ref0(tagContent).optional().trim() &
        ref0(filter).star().trim() &
        tagEnd();
    final endTag = tagStart() & string('endclip_rect').trim() & tagEnd();

    return (start & ref0(element).starLazy(endTag) & endTag).map((values) {
      final content = collapseTextNodes(values[2] as List<ASTNode>? ?? []);
      final filters = (values[3] as List).cast<Filter>();
      final nonFilterContent =
          content.where((node) => node is! Filter).toList();
      return Tag(
        'clip_rect',
        nonFilterContent,
        filters: filters,
        body: values[5].cast<ASTNode>(),
      );
    });
  }

  Clip _parseClipBehavior(Evaluator evaluator) {
    Clip? clip;
    for (final arg in namedArgs) {
      final name = arg.identifier.name;
      final value = evaluator.evaluate(arg.value);
      switch (name) {
        case 'clip':
        case 'clipBehavior':
          clip = parseClip(value);
          break;
        default:
          handleUnknownArg('clip_rect', name);
          break;
      }
    }
    return switch (clip) {
      null => Clip.hardEdge,
      final resolved => resolved,
    };
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

class _ClipRRectConfig {
  BorderRadiusGeometry? borderRadius;
  Clip? clipBehavior;
}

Widget _build(_ClipRRectConfig config, List<Widget> children) {
  final child = wrapChildren(children);
  return ClipRRect(
    borderRadius: config.borderRadius ?? BorderRadius.zero,
    clipBehavior: switch (config.clipBehavior) {
      null => Clip.antiAlias,
      final clip => clip,
    },
    child: child,
  );
}

Widget _buildClipOval(Clip clip, List<Widget> children) {
  final child = wrapChildren(children);
  return ClipOval(
    clipBehavior: clip,
    child: child,
  );
}

Widget _buildClipRect(Clip clip, List<Widget> children) {
  final child = wrapChildren(children);
  return ClipRect(
    clipBehavior: clip,
    child: child,
  );
}

List<Widget> _asWidgets(Object? value) {
  return WidgetTagBase.asWidgets(value);
}
