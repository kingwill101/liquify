import 'dart:convert';

import 'package:liquify/liquify.dart';
import 'package:liquify_ui/src/ui_nodes.dart';

class UiRenderTarget extends RenderTarget<UiDocument> {
  const UiRenderTarget();

  @override
  RenderSink createSink() => UiRenderSink();

  @override
  UiDocument finalize(RenderSink sink) {
    final value = sink.result();
    if (value is List<UiNode>) {
      return UiDocument(nodes: value);
    }
    if (value is UiDocument) {
      return value;
    }
    if (value is UiNode) {
      return UiDocument(nodes: [value]);
    }
    if (value == null) {
      return UiDocument(nodes: const []);
    }
    return UiDocument(nodes: [UiText(value.toString())]);
  }
}

class UiRenderSink extends RenderSink {
  final List<UiNode> _nodes = [];

  @override
  void write(Object? value) {
    if (value == null) {
      return;
    }
    if (value is UiNode) {
      _appendNode(value);
      return;
    }
    if (value is UiDocument) {
      _mergeNodes(value.nodes);
      return;
    }
    if (value is Iterable) {
      for (final entry in value) {
        write(entry);
      }
      return;
    }
    _appendText(value.toString());
  }

  @override
  void writeln([Object? value]) {
    write(value);
    write('\n');
  }

  @override
  void clear() {
    _nodes.clear();
  }

  @override
  RenderSink spawn() => UiRenderSink();

  @override
  void merge(RenderSink other) {
    final value = other.result();
    if (value is List<UiNode>) {
      _mergeNodes(value);
      return;
    }
    if (value is UiDocument) {
      _mergeNodes(value.nodes);
      return;
    }
    if (value is UiNode) {
      _appendNode(value);
      return;
    }
    if (value == null) {
      return;
    }
    _appendText(value.toString());
  }

  @override
  Object? result() => List<UiNode>.from(_nodes);

  @override
  String debugString() => jsonEncode(UiDocument(nodes: _nodes).toJson());

  void _appendNode(UiNode node) {
    if (node is UiText) {
      _appendText(node.text);
      return;
    }
    _nodes.add(node);
  }

  void _appendText(String text) {
    if (text.isEmpty) {
      return;
    }
    final last = _nodes.isNotEmpty ? _nodes.last : null;
    if (last is UiText) {
      _nodes[_nodes.length - 1] = UiText('${last.text}$text');
      return;
    }
    _nodes.add(UiText(text));
  }

  void _mergeNodes(List<UiNode> nodes) {
    for (final node in nodes) {
      _appendNode(node);
    }
  }
}
