import 'package:file/file.dart';
import 'package:file/local.dart';

/// A file system implementation that resolves template paths relative to a base directory.
///
/// Uses a [FileSystem] to interact with the underlying storage and resolves all paths
/// relative to [baseDir].
///
/// ```dart
/// final root = FileSystemRoot('/templates');
/// final source = root.resolve('header.liquid');
/// print(source.content); // Contents of /templates/header.liquid
/// ```
class FileSystemRoot implements Root {
  final FileSystem fileSystem;
  final Directory baseDir;

  FileSystemRoot(String basePath, {FileSystem? fileSystem})
      : fileSystem = fileSystem ?? LocalFileSystem(),
        baseDir = (fileSystem ?? LocalFileSystem())
            .directory(fileSystem!.path.normalize(basePath));

  @override
  Source resolve(String relPath) {
    final file = baseDir.childFile(fileSystem.path.normalize(relPath));
    if (!file.existsSync()) {
      throw Exception('Template file not found: $relPath');
    }
    final content = file.readAsStringSync();
    return Source(file.uri, content, this);
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    final file = baseDir.childFile(fileSystem.path.normalize(relPath));
    if (!await file.exists()) {
      throw Exception('Template file not found: $relPath');
    }
    final content = await file.readAsString();
    return Source(file.uri, content, this);
  }
}

/// Base interface for template resolution systems.
///
/// Implementations can load templates from different storage systems like
/// file systems, memory maps, or remote servers.
abstract class Root {
  /// Synchronously resolves a template path to a Source
  Source resolve(String relPath);

  /// Asynchronously resolves a template path to a Source
  ///
  /// Default implementation calls sync resolve, but implementations
  /// should override this for true async operation when needed.
  Future<Source> resolveAsync(String relPath) async {
    return resolve(relPath);
  }
}

/// An in-memory implementation of [Root] that stores templates in a [Map].
///
/// Useful for testing or small template sets that can be stored in memory.
///
/// ```dart
/// final root = MapRoot({
///   'greeting': 'Hello {{name}}!',
///   'footer': '© {{year}}'
/// });
/// ```
class MapRoot implements Root {
  final Map<String, String> _templates;

  MapRoot(this._templates);

  @override
  Source resolve(String path) {
    if (_templates.containsKey(path)) {
      return Source(null, _templates[path]!, this);
    }
    return Source(null, '', this);
  }

  @override
  Future<Source> resolveAsync(String path) async {
    if (_templates.containsKey(path)) {
      return Source(null, _templates[path]!, this);
    }
    return Source(null, '', this);
  }
}

/// A resolved template's content and metadata.
///
/// Contains the template [content] along with optional [file] location and [root]
/// reference. Created by [Root] implementations when resolving templates.
///
/// ```dart
/// // Create a simple source from a string
/// final source = Source.fromString('Hello {{name}}!');
///
/// // Create from async content
/// final source = await Source.fromAsync(fetchRemoteTemplate());
/// ```
class Source {
  final Uri? file;
  final String content;
  final Root? root;

  Source(this.file, this.content, this.root);

  Source.fromString(String content) : this(null, content, null);

  /// Creates a Source from an async content provider
  static Future<Source> fromAsync(
    Future<String> contentFuture, {
    Uri? file,
    Root? root,
  }) async {
    final content = await contentFuture;
    return Source(file, content, root);
  }
}
