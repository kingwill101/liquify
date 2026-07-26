import 'package:file/file.dart' show FileSystem, Directory;
import 'package:file/memory.dart';
import 'package:liquify/src/fs/root.dart';

/// A file system implementation that resolves template paths relative to a base directory.
class FSystemRoot implements Root {
  final FileSystem fileSystem;
  final Directory baseDir;
  final List<String> _extensions;
  final bool throwOnMissing;

  FSystemRoot(
    String basePath, {
    FileSystem? fileSystem,
    List<String>? extensions,
    this.throwOnMissing = false,
    Directory? base,
  }) : _extensions = extensions ?? ['.liquid', '.html'],
       fileSystem = fileSystem ?? MemoryFileSystem(),
       baseDir =
           (base ??
           (fileSystem ?? MemoryFileSystem()).directory(
             (fileSystem ?? MemoryFileSystem()).path.normalize(basePath),
           ));

  @override
  Source resolve(String relPath) {
    if (fileSystem.path.extension(relPath).isEmpty) {
      for (final ext in _extensions) {
        final file = baseDir.childFile(
          fileSystem.path.normalize('$relPath$ext'),
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
        final file = baseDir.childFile(
          fileSystem.path.normalize('$relPath$ext'),
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

class FileSystemRoot extends FSystemRoot {
  FileSystemRoot(
    super.basePath, {
    FileSystem? fileSystem,
    super.extensions,
    super.throwOnMissing = false,
    super.base,
  }) : super(fileSystem: fileSystem ?? MemoryFileSystem());
}
