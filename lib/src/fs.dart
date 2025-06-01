import 'package:file/file.dart';
import 'package:file/local.dart';

/// A file system implementation that resolves template paths relative to a base directory.
///
/// Uses a [FileSystem] to interact with the underlying storage and resolves all paths
/// relative to [baseDir].
///
/// Supports extension fallback: if the requested template path has no extension,
/// [FileSystemRoot] will try appending each extension in [extensions] (default: ['.liquid', '.html'])
/// until a file is found.
///
/// By default, if a template is missing, [FileSystemRoot] returns an empty [Source].
/// If [throwOnMissing] is set to true, it throws a [TemplateNotFoundException] instead.
///
/// Example:
///
/// final root = FileSystemRoot('/templates');
/// final source = root.resolve('header'); // will resolve to header.liquid or header.html if present
/// print(source.content);
///
class FileSystemRoot implements Root {
  final FileSystem fileSystem;
  final Directory baseDir;
  final List<String> _extensions;
  final bool throwOnMissing;

  FileSystemRoot(String basePath,
      {FileSystem? fileSystem,
      List<String>? extensions,
      this.throwOnMissing = false})
      : _extensions = extensions ?? ['.liquid', '.html'],
        fileSystem = fileSystem ?? LocalFileSystem(),
        baseDir = (fileSystem ?? LocalFileSystem()).directory(
            (fileSystem ?? LocalFileSystem()).path.normalize(basePath));

  @override
  Source resolve(String relPath) {
    if (fileSystem.path.extension(relPath).isEmpty) {
      for (final ext in _extensions) {
        final file =
            baseDir.childFile(fileSystem.path.normalize('$relPath$ext'));
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          return Source(file.uri, content, this);
        }
      }
      if (throwOnMissing) {
        throw TemplateNotFoundException(relPath);
      } else {
        return Source(null, '', this);
      }
    }

    final file = baseDir.childFile(fileSystem.path.normalize(relPath));
    if (!file.existsSync()) {
      if (throwOnMissing) {
        throw TemplateNotFoundException(relPath);
      } else {
        return Source(null, '', this);
      }
    }
    final content = file.readAsStringSync();
    return Source(file.uri, content, this);
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    if (fileSystem.path.extension(relPath).isEmpty) {
      for (final ext in _extensions) {
        final file =
            baseDir.childFile(fileSystem.path.normalize('$relPath$ext'));
        if (await file.exists()) {
          final content = await file.readAsString();
          return Source(file.uri, content, this);
        }
      }
      if (throwOnMissing) {
        throw TemplateNotFoundException(relPath);
      } else {
        return Source(null, '', this);
      }
    }

    final file = baseDir.childFile(fileSystem.path.normalize(relPath));
    if (!await file.exists()) {
      if (throwOnMissing) {
        throw TemplateNotFoundException(relPath);
      } else {
        return Source(null, '', this);
      }
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
/// Supports extension fallback: if the requested template path has no extension,
/// [MapRoot] will try appending each extension in [extensions] (default: ['.liquid', '.html'])
/// until a template is found.
///
/// By default, if a template is missing, [MapRoot] returns an empty [Source].
/// If [throwOnMissing] is set to true, it throws a [TemplateNotFoundException] instead.
///
/// Example:
///
/// final root = MapRoot({
///   'greeting.liquid': 'Hello {{name}}!',
///   'footer.html': '© {{year}}'
/// }, throwOnMissing: true);
/// final source = root.resolve('greeting'); // will resolve to greeting.liquid
/// print(source.content);
///
class MapRoot implements Root {
  final Map<String, String> _templates;
  final bool throwOnMissing;
  final List<String> _extensions;

  MapRoot(this._templates,
      {this.throwOnMissing = false, List<String>? extensions})
      : _extensions = extensions ?? ['.liquid', '.html'];

  @override
  Source resolve(String relPath) {
    if (relPath.isEmpty) return Source(null, '', this);

    // Check for exact match first
    if (_templates.containsKey(relPath)) {
      return Source(null, _templates[relPath]!, this);
    }

    // Check with extensions if no extension is present
    if (LocalFileSystem().path.extension(relPath).isEmpty) {
      for (final ext in _extensions) {
        final keyWithExt = LocalFileSystem().path.normalize('$relPath$ext');
        if (_templates.containsKey(keyWithExt)) {
          return Source(null, _templates[keyWithExt]!, this);
        }
      }
    }

    // Template not found
    if (throwOnMissing) {
      throw TemplateNotFoundException(relPath);
    } else {
      return Source(null, '', this);
    }
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    return Future.sync(() => resolve(relPath));
  }
}

/// Exception thrown when a template is not found.
///
/// Contains the [path] that was attempted to be resolved.
class TemplateNotFoundException implements Exception {
  final String path;

  TemplateNotFoundException(this.path);

  @override
  String toString() => 'TemplateNotFoundException: $path';
}

/// Represents a resolved template source.
///
/// Contains the [file] of the template, its [content], and the [Root] that resolved it.
class Source {
  final Uri? file;
  final String content;
  final Root root;

  Source(this.file, this.content, this.root);
}
