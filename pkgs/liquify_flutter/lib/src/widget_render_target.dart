import 'package:flutter/material.dart';
import 'package:liquify/liquify.dart';

class WidgetRenderTarget extends RenderTarget<Widget> {
  const WidgetRenderTarget();

  @override
  RenderSink createSink() => WidgetRenderSink();

  @override
  Widget finalize(RenderSink sink) {
    final value = sink.result();
    if (value is Widget) {
      return value;
    }
    if (value is List<Widget>) {
      return _wrapWidgets(value);
    }
    return const SizedBox.shrink();
  }
}

class WidgetRenderSink extends RenderSink {
  final List<Widget> _widgets = [];

  @override
  void write(Object? value) {
    if (value == null) {
      return;
    }
    if (value is Widget) {
      _widgets.add(value);
      return;
    }
    if (value is Iterable) {
      for (final entry in value) {
        write(entry);
      }
      return;
    }
    // Ignore non-widget values to keep the tree tag-driven only.
  }

  @override
  void writeln([Object? value]) {
    write(value);
    write('\n');
  }

  @override
  void clear() {
    _widgets.clear();
  }

  @override
  RenderSink spawn() => WidgetRenderSink();

  @override
  void merge(RenderSink other) {
    final value = other.result();
    if (value is List<Widget>) {
      _widgets.addAll(value);
      return;
    }
    if (value is Widget) {
      _widgets.add(value);
      return;
    }
  }

  @override
  Object? result() => List<Widget>.from(_widgets);

  @override
  String debugString() => 'WidgetRenderSink(${_widgets.length} widgets)';
}

Widget _wrapWidgets(List<Widget> widgets) {
  final filtered = widgets.where((widget) {
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }).toList();
  if (filtered.isEmpty) {
    return const SizedBox.shrink();
  }
  final scaffold = filtered.whereType<Scaffold>();
  if (scaffold.isNotEmpty) {
    return scaffold.first;
  }
  if (filtered.length == 1) {
    return filtered.first;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: filtered,
  );
}
