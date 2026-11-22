import 'dart:convert';

String _renderLiquidValue(Object? value) => switch (value) {
  null => '',
  List() => value.map(_renderLiquidValue).join(),
  Map() => _inspectLiquidValue(value),
  _ => value.toString(),
};

String _inspectLiquidValue(Object? value) => switch (value) {
  null => 'nil',
  String() => jsonEncode(value),
  List() => '[${value.map(_inspectLiquidValue).join(', ')}]',
  Map() =>
    '{${value.entries.map((entry) {
      return '${_inspectLiquidValue(entry.key)}=>${_inspectLiquidValue(entry.value)}';
    }).join(', ')}}',
  _ => value.toString(),
};

abstract class RenderTarget<R> {
  const RenderTarget();

  RenderSink createSink();

  R finalize(RenderSink sink);
}

abstract class RenderSink {
  void write(Object? value);

  void writeln([Object? value]);

  void clear();

  RenderSink spawn();

  void merge(RenderSink other);

  Object? result();

  String debugString();
}

class StringRenderTarget extends RenderTarget<String> {
  const StringRenderTarget();

  @override
  RenderSink createSink() => StringRenderSink();

  @override
  String finalize(RenderSink sink) {
    final value = sink.result();
    return value == null ? '' : value.toString();
  }
}

class StringRenderSink extends RenderSink {
  final StringBuffer _buffer = StringBuffer();

  @override
  void write(Object? value) {
    _buffer.write(_renderLiquidValue(value));
  }

  @override
  void writeln([Object? value]) {
    write(value);
    _buffer.writeln();
  }

  @override
  void clear() {
    _buffer.clear();
  }

  @override
  RenderSink spawn() => StringRenderSink();

  @override
  void merge(RenderSink other) {
    final value = other.result();
    if (value == null) {
      return;
    }
    _buffer.write(value.toString());
  }

  @override
  Object? result() => _buffer.toString();

  @override
  String debugString() => _buffer.toString();
}
