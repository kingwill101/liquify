import 'package:liquify/src/fs.dart';

class TestRoot implements Root {
  final Map<String, String> files = {};

  @override
  Future<Source> resolveAsync(String path) async {
    final content = files[path];
    if (content == null) throw Exception('File not found: $path');
    return Source(Uri.parse(path), content, this);
  }

  @override
  Source resolve(String path) {
    final content = files[path];
    if (content == null) throw Exception('File not found: $path');
    return Source(Uri.parse(path), content, this);
  }

  void addFile(String path, String content) {
    files[path] = content;
  }
}
