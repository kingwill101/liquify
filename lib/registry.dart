class TagRegistry {
  static final List<String> _tags = [
    'assign',
    'capture',
    'comment',
    'cycle',
    'for',
    'if',
    'case',
    'when',
    'liquid',
    'raw',
  ];

  static void register(String name) {
    _tags.add(name);
  }

  static List<String> get tags => _tags;
}
