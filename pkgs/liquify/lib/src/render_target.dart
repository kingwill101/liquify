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
    if (value == null) {
      _buffer.write('');
    } else {
      _buffer.write(value.toString());
    }
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
