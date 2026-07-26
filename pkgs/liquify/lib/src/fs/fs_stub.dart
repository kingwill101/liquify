import 'package:liquify/src/fs/root.dart';

/// Browser-safe stub that keeps the `FileSystemRoot` API available to analysis.
class FileSystemRoot implements Root {
  FileSystemRoot(
    String basePath, {
    Object? fileSystem,
    List<String>? extensions,
    bool throwOnMissing = false,
    Object? base,
  });

  @override
  Source resolve(String relPath) {
    throw UnsupportedError('FileSystemRoot is not supported on this platform.');
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    throw UnsupportedError('FileSystemRoot is not supported on this platform.');
  }
}
