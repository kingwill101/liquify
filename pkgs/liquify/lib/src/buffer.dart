import 'package:liquify/src/render_target.dart';

class Buffer {
  Buffer({RenderSink? sink}) : _sink = sink ?? StringRenderSink();

  final RenderSink _sink;

  /// Writes the given object to the buffer.
  ///
  /// If the object is null, an empty string is written.
  void write(Object? obj) {
    _sink.write(obj);
  }

  /// Writes the given object to the buffer, followed by a newline.
  ///
  /// If no object is provided, only a newline is written.
  void writeln([Object? obj]) {
    _sink.writeln(obj);
  }

  /// Returns the contents of the buffer as a string.
  @override
  String toString() => _sink.debugString();

  /// Clears the contents of the buffer.
  void clear() {
    _sink.clear();
  }

  /// Returns the length of the buffer's contents.
  int get length => toString().length;

  /// Returns true if the buffer is empty.
  bool get isEmpty => length == 0;

  /// Returns true if the buffer is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Returns a new buffer spawned from the same sink type.
  Buffer spawn() => Buffer(sink: _sink.spawn());

  /// Merges another buffer into this buffer.
  void merge(Buffer other) => _sink.merge(other._sink);

  /// Returns the structured value of the underlying sink.
  Object? value() => _sink.result();
}
