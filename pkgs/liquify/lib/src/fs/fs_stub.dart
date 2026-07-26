import 'package:liquify/src/fs/root.dart';

export 'package:liquify/src/fs/root.dart';

class FSystemRoot implements Root {
  final dynamic _fileSystem;
  final dynamic _baseDir;
  final List<String> _extensions;
  final bool throwOnMissing;

  FSystemRoot(
    String basePath, {
    required dynamic fileSystem,
    List<String>? extensions,
    this.throwOnMissing = false,
    dynamic base,
  }) : _fileSystem = fileSystem,
       _extensions = extensions ?? ['.liquid', '.html'],
       _baseDir =
           base ?? fileSystem.directory(fileSystem.path.normalize(basePath));

  @override
  Source resolve(String relPath) {
    if (_fileSystem.path.extension(relPath).isEmpty) {
      for (final ext in _extensions) {
        final file = _baseDir.childFile(
          _fileSystem.path.normalize('$relPath$ext'),
        );
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

    final file = _baseDir.childFile(_fileSystem.path.normalize(relPath));
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
    if (_fileSystem.path.extension(relPath).isEmpty) {
      for (final ext in _extensions) {
        final file = _baseDir.childFile(
          _fileSystem.path.normalize('$relPath$ext'),
        );
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

    final file = _baseDir.childFile(_fileSystem.path.normalize(relPath));
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

class FileSystemRoot extends FSystemRoot {
  FileSystemRoot(
    super.basePath, {
    dynamic fileSystem,
    super.extensions,
    super.throwOnMissing = false,
    super.base,
  }) : super(fileSystem: fileSystem ?? _requireFileSystem());
}

Never _requireFileSystem() =>
    throw StateError('FileSystem must be provided on this platform.');
