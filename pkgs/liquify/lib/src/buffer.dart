class Buffer {
  final StringBuffer _buffer = StringBuffer();

  /// Writes the given object to the buffer.
  ///
  /// If the object is null, an empty string is written.
  void write(Object? obj) {
    if (obj == null) {
      _buffer.write('');
    } else {
      _buffer.write(obj.toString());
    }
  }

  /// Writes the given object to the buffer, followed by a newline.
  ///
  /// If no object is provided, only a newline is written.
  void writeln([Object? obj]) {
    write(obj);
    _buffer.writeln();
  }

  /// Returns the contents of the buffer as a string.
  @override
  String toString() => _buffer.toString();

  /// Clears the contents of the buffer.
  void clear() {
    _buffer.clear();
  }

  /// Returns the length of the buffer's contents.
  int get length => _buffer.length;

  /// Returns true if the buffer is empty.
  bool get isEmpty => _buffer.isEmpty;

  /// Returns true if the buffer is not empty.
  bool get isNotEmpty => _buffer.isNotEmpty;
}
