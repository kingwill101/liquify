import 'package:file/file.dart' show FileSystem;
import 'package:file/memory.dart';
import 'package:liquify/src/fs/root.dart';

/// A file system implementation that resolves template paths relative to a base directory.
class FileSystemRoot extends FSystemRoot {
  FileSystemRoot(
    super.basePath, {
    FileSystem? fileSystem,
    super.extensions,
    super.throwOnMissing = false,
    super.base,
  }) : super(fileSystem: MemoryFileSystem());
}
