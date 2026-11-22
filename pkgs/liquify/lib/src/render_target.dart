import 'dart:convert';

String liquidValueToString(Object? value) =>
    _liquidString(value, Set<Object>.identity(), inspect: false);

String _liquidString(
  Object? value,
  Set<Object> active, {
  required bool inspect,
}) {
  if (value == null) return inspect ? 'nil' : '';
  if (value is String) return inspect ? jsonEncode(value) : value;

  if (value is List) {
    if (!active.add(value)) return '[...]';
    try {
      final items = value.map(
        (item) => _liquidString(item, active, inspect: inspect),
      );
      return inspect ? '[${items.join(', ')}]' : items.join();
    } finally {
      active.remove(value);
    }
  }
  if (value is Map) {
    if (!active.add(value)) return '{...}';
    try {
      final entries = value.entries.map((entry) {
        final key = _liquidString(entry.key, active, inspect: true);
        final item = _liquidString(entry.value, active, inspect: true);
        return '$key=>$item';
      });
      return '{${entries.join(', ')}}';
    } finally {
      active.remove(value);
    }
  }
  return value.toString();
}

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
    _buffer.write(liquidValueToString(value));
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
