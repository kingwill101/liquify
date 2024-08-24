import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

class FileSystemRoot implements Root {
  final FileSystem fileSystem;
  final Directory baseDir;

  FileSystemRoot(String basePath, {FileSystem? fileSystem})
      : fileSystem = fileSystem ?? LocalFileSystem(),
        baseDir = (fileSystem ?? LocalFileSystem()).directory(basePath);

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

abstract class Root {
  Source resolve(String relPath);
}

class Source {
  final Uri? file;
  final String content;
  final Root? root;

  Source(this.file, this.content, this.root);

  Source.fromString(String content) : this(null, content, null);
}
