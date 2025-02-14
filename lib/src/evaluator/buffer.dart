part of 'evaluator.dart';

extension BufferHandling on Evaluator {
  Buffer get currentBuffer =>
      _blockBuffers.isEmpty ? buffer : _blockBuffers.last;

  void startBlockCapture() {
    pushBuffer();
  }

  String endBlockCapture() {
    return popBuffer();
  }

  bool isCapturingBlock() {
    return _blockBuffers.isNotEmpty;
  }

  void pushBuffer() {
    _blockBuffers.add(Buffer());
  }

  String popBuffer() {
    if (_blockBuffers.isEmpty) {
      throw Exception('No block buffer to pop');
    }
    return _blockBuffers.removeLast().toString();
  }
}
