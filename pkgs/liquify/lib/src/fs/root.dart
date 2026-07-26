/// Exception thrown when a template is not found.
class TemplateNotFoundException implements Exception {
  final String path;

  TemplateNotFoundException(this.path);

  @override
  String toString() => 'TemplateNotFoundException: $path';
}

/// Represents a resolved template source.
class Source {
  final Uri? file;
  final String content;
  final Root root;

  Source(this.file, this.content, this.root);
}

/// Base interface for template resolution systems.
abstract class Root {
  Source resolve(String relPath);

  Future<Source> resolveAsync(String relPath) async {
    return resolve(relPath);
  }
}

/// An in-memory implementation of [Root] that stores templates in a [Map].
class MapRoot implements Root {
  final Map<String, String> _templates;
  final bool throwOnMissing;
  final List<String> _extensions;

  MapRoot(
    this._templates, {
    this.throwOnMissing = false,
    List<String>? extensions,
  }) : _extensions = extensions ?? ['.liquid', '.html'];

  @override
  Source resolve(String relPath) {
    if (relPath.isEmpty) return Source(null, '', this);

    if (_templates.containsKey(relPath)) {
      return Source(null, _templates[relPath]!, this);
    }

    if (!_hasExtension(relPath)) {
      for (final ext in _extensions) {
        final keyWithExt = '$relPath$ext';
        if (_templates.containsKey(keyWithExt)) {
          return Source(null, _templates[keyWithExt]!, this);
        }
      }
    }

    if (throwOnMissing) {
      throw TemplateNotFoundException(relPath);
    } else {
      return Source(null, '', this);
    }
  }

  @override
  Future<Source> resolveAsync(String relPath) async {
    return resolve(relPath);
  }

  static bool _hasExtension(String path) {
    final i = path.lastIndexOf('.');
    if (i == -1) return false;
    return i > path.lastIndexOf('/');
  }
}
