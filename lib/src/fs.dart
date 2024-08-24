import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

/// Represents a root file system that can resolve relative paths to [Source] objects.
///
/// The [FileSystemRoot] class provides a way to access files in a file system
/// by resolving relative paths to [Source] objects. It uses a [FileSystem]
/// implementation to interact with the underlying file system, and a base
/// directory to resolve relative paths.
class FileSystemRoot implements Root {
  final FileSystem fileSystem;
  final Directory baseDir;

  FileSystemRoot(String basePath, {FileSystem? fileSystem})
      : fileSystem = fileSystem ?? LocalFileSystem(),
        baseDir = (fileSystem ?? LocalFileSystem()).directory(basePath);

  /// Resolves a relative file path to a [Source] object.
  ///
  /// Given a relative file path [relPath], this method will resolve the path
  /// relative to the [baseDir] directory of this [FileSystemRoot] instance.
  /// If the file exists, it will read the file contents and return a [Source]
  /// object representing the file. If the file does not exist, it will throw
  /// an [Exception].
  ///
  /// @param relPath The relative file path to resolve.
  /// @return A [Source] object representing the resolved file.
  /// @throws Exception if the file does not exist.
  @override
  Source resolve(String relPath) {
    final file = baseDir.childFile(path.normalize(relPath));
    if (!file.existsSync()) {
      throw Exception('Template file not found: $relPath');
    }
    final content = file.readAsStringSync();
    return Source(file.uri, content, this);
  }
}

/// Represents a root file system that can resolve relative paths to [Source] objects.
///
/// The `Root` interface provides a way to access files in a file system
/// by resolving relative paths to `Source` objects.
abstract class Root {
  Source resolve(String relPath);
}

/// Represents a source file or content, with an optional file URI and root directory.
///
/// The `Source` class encapsulates the content of a file, along with its optional
/// file URI and the root directory it belongs to. This class is used to represent
/// the source of a file or content that can be resolved relative to a file system
/// root.
class Source {
  final Uri? file;
  final String content;
  final Root? root;

  Source(this.file, this.content, this.root);

  Source.fromString(String content) : this(null, content, null);
}
