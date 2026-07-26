class Platform {
  static const Map<String, String> environment = {};
  static const String pathSeparator = '/';
}

class _Path {
  final String path;
  const _Path(this.path);
}

class File extends _Path {
  File(super.path);

  bool existsSync() => false;
  String readAsStringSync() => '';
  void writeAsStringSync(String contents) {}
}

class Directory extends _Path {
  Directory(super.path);

  static final Directory current = Directory('.');
  static final Directory systemTemp = Directory('/tmp');

  Directory get parent => Directory(path == '/' ? '/' : '/');
  bool existsSync() => false;
  void createSync({bool recursive = false}) {}
  Directory get absolute => this;
  Directory createTempSync(String prefix) => this;
  void deleteSync({bool recursive = false}) {}
}
